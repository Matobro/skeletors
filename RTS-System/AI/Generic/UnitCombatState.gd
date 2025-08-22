extends Node
class_name UnitCombatState

var ai
var parent

var current_target: Node = null
var attack_timer: float = 0.0
var aggro_timer: float = 0.0
var attack_anim_timer: float = 0.0
var time_since_start: float = 0.0

var is_attack_committed: bool = false
var has_attacked: bool = false

var recent_attackers: Array[Dictionary] = []

const ATTACKER_MEMORY := 1.5
const AGGRO_CHECK_INTERVAL := 0.25

func _init(_ai, _parent):
	ai = _ai
	parent = _parent

func clear_combat_state():
	ai.parent.unit_visual.clear_target()
	current_target = null
	is_attack_committed = false
	has_attacked = false
	attack_anim_timer = 0.0
	aggro_timer = 0.0
	recent_attackers.clear()

func update(delta: float) -> void:
	time_since_start += delta
	aggro_timer += delta
	attack_timer -= delta

	# Remove expired attackers from memory
	recent_attackers = recent_attackers.filter(
		func(record): return time_since_start - record["time"] < ATTACKER_MEMORY
	)

	if ai.state not in ["Attack", "Attack_move", "Idle"]:
		return

	check_for_targets()

func check_for_targets():
	if !is_player_command() or ai.state == "Attack_move":
		# Switch targets if better one available
		for unit in recent_attackers:
			var attacker: Node = unit["attacker"]
			if attacker != null and is_instance_valid(attacker) and !attacker.unit_combat.dead:
				if should_switch_target(attacker):
					set_target(attacker)
					return

	# Aggro check if is player commanded attack move or is not a player command
	if (is_player_command() and ai.state == "Attack_move") or !is_player_command():
		if aggro_timer >= AGGRO_CHECK_INTERVAL:
			aggro_timer = 0.0
			var enemy = parent.unit_combat.closest_enemy_in_aggro_range()
			if enemy != null and should_switch_target(enemy):
				set_target(enemy)
				return
	else:
		set_target(ai.command_handler.current_command.target_unit)

	# Clear state if no targets found
	if current_target == null or !is_instance_valid(current_target) or current_target.unit_combat.dead:
		clear_combat_state()

func on_attacked_by(attacker: Node) -> void:
	if attacker == null or !is_instance_valid(attacker) or attacker.unit_combat.dead:
		return

	recent_attackers.append({
		"attacker": attacker,
		"time": time_since_start
	})

func set_target_from_command() -> void:
	var cmd = ai.get_current_command()
	if cmd != {} and cmd.has("target_unit") and is_instance_valid(cmd.target_unit):
		set_target(cmd.target_unit)

func should_switch_target(new_target: Node) -> bool:
	# Switch if target is invalid
	if current_target == null or !is_instance_valid(current_target) or current_target.unit_combat.dead:
		return true

	# Switch if theres a target closer (with buffer range to avoid constant switching)
	var current_dist = parent.global_position.distance_to(current_target.global_position)
	var new_dist = parent.global_position.distance_to(new_target.global_position)
	return new_dist + 32 < current_dist

func is_player_command() -> bool:
	var cmd = ai.command_handler.current_command
	return cmd.is_player_command if cmd.has("is_player_command") else false

func set_target(target: Node) -> void:
	# Check if target is valid
	if target == null or !is_instance_valid(target) or target.unit_combat.dead:
		return

	# Set target
	current_target = target
	ai.parent.unit_visual.set_target(target)
	# Que attack command if attack moving
	if ai.state == "Attack_move":
		parent.command_holder.insert_command_at_front({
			"type": "Attack",
			"target_unit": target,
			"target_position": target.global_position,
			"is_player_command": false,
			"is_queued": true
		})
		# Save attack move command so we can return to it
		ai.command_handler.fallback_command = ai.command_handler.current_command
		ai.command_handler.process_next_command()
