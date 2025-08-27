extends Node

class_name BaseAbility

@export var ability_data: AbilityData

var current_cooldown: float = 0.0

func tick(delta: float):
	if current_cooldown > 0:
		current_cooldown = max(current_cooldown - delta, 0)

func can_cast(caster) -> bool:
	return current_cooldown <= 0 and caster.data.stats.current_mana >= ability_data.mana_cost

func start_cast(caster, target_position: Vector2 = Vector2.ZERO, target_unit = null):
	if !can_cast(caster):
		return false

	match ability_data.spell_type:
		"TargetedProjectile":
			_cast_projectile(caster, target_unit)
			pass
		"GroundArea":
			#_cast_ground_area(caster, target_position)
			pass
		"NoTarget":
			#_cast_no_target(caster)
			pass
		"Aura":
			#_cast_aura(caster)
			pass
		"BuffAbility":
			#_cast_buff(caster, target_unit)
			pass
		_:
			print("Unknown spell type:", ability_data.spell_type)

	return true

func _cast_projectile(caster, target_unit):
	if !ability_data.projectile_scene or !target_unit:
		return
	
	var projectile = ability_data.projectile_scene.instantiate()
	projectile.global_position = caster.global_position
	projectile.target = target_unit
	projectile.effects = ability_data.effects.duplicate()
	projectile.source_ability = self
	projectile.caster = caster
	caster.get_tree().current_scene.add_child(projectile)
	caster.data.stats.current_mana -= ability_data.mana_cost
	current_cooldown = ability_data.cooldown
	

func apply_effect(effect: EffectData, caster, target_position: Vector2, target_unit = null):
	match effect.effect_type:
		"Damage":
			if target_unit:
				target_unit.unit_combat.take_damage(effect.amount)
		"Heal":
			if target_unit:
				target_unit.unit_combat.heal_health(effect.amount)
		"Buff":
			if target_unit:
				target_unit.unit_combat.add_buff(effect)
		"Debuff":
			if target_unit:
				target_unit.unit_combat.add_debuff(effect)
		"Stun":
			if target_unit:
				target_unit.unit_combat.get_stunned(effect.duration)
		"Slow":
			if target_unit:
				target_unit.unit_combat.apply_slow(effect.amount, effect.duration)
		"Summon":
			pass
			#_spawn_summon(effect, caster, target_position)
		"Custom":
			if effect.extra.has("callback"):
				var cb = effect.extra["callback"]
				if cb is Callable:
					cb.call(caster, target_unit, target_position)
