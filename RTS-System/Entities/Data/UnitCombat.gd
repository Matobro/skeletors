extends Node

class_name UnitCombat

var dead: bool = false
var is_invunerable: bool = true

var possible_targets: Array[Unit]
var friendly_targets: Array[Unit]

var active_buffs: Array = []

var parent: Unit
var stats: BaseStatData

func _init(parent_ref, stats_ref) -> void:
	parent = parent_ref
	stats = stats_ref
	is_invunerable = false

func tick(delta):
	if dead: return
	for i in range(active_buffs.size() - 1, -1, -1):
		var buff = active_buffs[i]
		buff.time_left -= delta
		if buff.time_left <= 0:
			remove_buff(buff.effect, buff.source)
			active_buffs.remove_at(i)
		else:
			active_buffs[i] = buff

func take_damage(damage: int = 0, attacker = null):
	if dead or is_invunerable: 
		return

	var reduction = 1.0 - StatModifiers.calculate_armor(stats.armor)
	var final_damage = damage * reduction
	apply_damage(final_damage, attacker)

	if attacker != null and attacker.owner_id != parent.owner_id:
		parent.unit_ai.combat_state.on_attacked_by(attacker)

func apply_damage(damage, attacker):
	if dead: return
	if damage > 0:
		var final_damage = clampi(damage, 1, 9999)
		stats.current_health -= final_damage
		stats.current_health = clamp(stats.current_health, 0, stats.max_health)
		parent.unit_visual.hp_bar.set_hp_bar(stats.current_health)
		DamageText.show_text(str(final_damage), parent.animation_player.global_position)
	
	if stats.current_health <= 0:
		handle_death()

	alert_nearby_allies(attacker)

func handle_death():
	if dead: return
	parent.unit_visual.set_selected(false)
	parent.hp_bar.set_bar_visible(false)
	dead = true
	parent.emit_signal("died", parent)
	parent.unit_ai.set_state("Dying")

func perform_attack():
	if dead: return
	if parent.unit_ai.combat_state.current_target != null:
		var attack_target = parent.unit_ai.combat_state.current_target
		var damage = StatModifiers.calculate_damage(stats.attack_dice_roll, stats.attack_damage)
		attack_target.unit_combat.take_damage(damage, parent)

func should_aggro(attacker) -> bool:
	if dead: return false
	if attacker and parent.unit_ai.current_state == parent.unit_ai.states["Idle"] and attacker.owner_id != parent.owner_id:
		return true
	
	return false

func get_attack_delay() -> float:
	var attack_speed = stats.attack_speed
	if attack_speed <= 0:
		attack_speed = 0.01
	return 1.0 / attack_speed

func alert_nearby_allies(attacker: Unit) -> void:
	for unit in friendly_targets:
		if !is_instance_valid(unit) or !is_instance_valid(unit.unit_combat) or !should_aggro(attacker):
			continue
		unit.unit_combat.on_social_aggro(attacker)

func on_social_aggro(attacker: Unit):
	if dead: return
	if parent.unit_ai.current_state == parent.unit_ai.states["Idle"]:
		parent.command_holder.issue_command(
			"Attack",
			attacker,
			attacker.global_position,
			false,
			parent.owner_id
		)

func add_buff(effect: EffectData, source: Unit):
	if dead: return
	var stat = effect.stat
	var amount = effect.amount

	for buff in active_buffs:
		if buff.effect == effect and buff.source == source:
			buff.time_left = effect.duration
			return

	if !stats.buff_bonus.has(stat):
		stats.buff_bonus[stat] = 0
	stats.buff_bonus[stat] += amount
	stats.recalculate_stats()

	if effect.duration > 0:
		active_buffs.append({
			"effect": effect,
			"time_left": effect.duration,
			"source": source
			})

func remove_buff(effect: EffectData, source: Unit):
	if dead: return
	for i in range(active_buffs.size() - 1, -1, -1):
		var buff = active_buffs[i]
		if buff.effect == effect and buff.source == source:
			var stat = effect.stat
			var amount = effect.amount
			if stats.buff_bonus.has(stat):
				stats.buff_bonus[stat] -= amount
				if abs(stats.buff_bonus[stat]) < 0.01:
					stats.buff_bonus.erase(stat)
			stats.recalculate_stats()
			break
	
func heal_health(heal_amount):
	stats.current_health = min(stats.current_health + heal_amount, stats.max_health)
	parent.hp_bar.set_hp_bar(stats.current_health)

func regenate_mana():
	if stats.health_regen <= 0:
		return
	
	stats.current_mana = min(stats.current_mana + stats.mana_regen, stats.max_mana)
	
func regenate_health():
	if stats.health_regen <= 0:
		return
	
	stats.current_health = min(stats.current_health + stats.health_regen, stats.max_health)
	parent.hp_bar.set_hp_bar(stats.current_health)

func get_stunned(_duration): #todo
	pass

func is_within_attack_range(_target) -> bool:
	return stats.attack_range > parent.global_position.distance_to(_target)

func compare_distance(target_a, target_b):
	return parent.position.distance_to(target_a.position) < parent.position.distance_to(target_b.position)

func closest_enemy_in_aggro_range() -> Unit:
	if possible_targets.size() <= 0:
		return null
		
	var closest_unit: Unit = null
	var closest_distance := INF

	var attack_target = parent.unit_ai.combat_state.current_target
	for unit in possible_targets:
		if unit.unit_combat.dead:
			if attack_target == unit:
				attack_target = null
			possible_targets.erase(unit)
		else:
			var dist := parent.position.distance_to(unit.position)
			if dist < closest_distance:
				closest_distance = dist
				closest_unit = unit

	return closest_unit

func closest_enemy_in_attack_range() -> Unit:
	var closest_unit = closest_enemy_in_aggro_range()
	if closest_unit and parent.position.distance_to(closest_unit.position) < stats.attack_range:
		return closest_unit
	return null
