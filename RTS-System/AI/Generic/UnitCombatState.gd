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
const AGGRO_CHECK_INTERVAL := 0.5

func _init(_ai, _parent):
	ai = _ai
	parent = _parent

func update(delta: float) -> void:
	if !is_valid_target(parent):
		return
	advance_timers(delta)
	clean_recent_attackers()

	if ai.state not in ["Attack", "Attack_move", "Idle"]:
		return

	check_for_targets()

func check_for_targets():
	# If not controlled (by player) or attack moving -> check targets
	if !is_player_command() or ai.state == "Attack_move":

		# Check recent attackers
		if switch_target_to_attacker():
			print("is valid attacker")
			return
		
		# Check close units
		if switch_target_aggro_check():
			return

	# If controlled (by player)
	else:
		set_target(ai.command_handler.current_command.target_unit)

	# Clear state if no targets found
	if !is_valid_target(current_target):
		clear_combat_state()

func should_switch_target(new_target: Node) -> bool:
	# Switch if target is invalid
	if !is_valid_target(current_target):
		return true
	
	# Switch if theres a target closer (with buffer range to avoid constant switching)
	var current_dist = parent.global_position.distance_to(current_target.global_position)
	var new_dist = parent.global_position.distance_to(new_target.global_position)
	return new_dist + 32 < current_dist

func set_target(target: Node, force = false) -> void:
	# Check if target is valid
	if !is_valid_target(target):
		return

	if !force:
		if target.owner_id == parent.owner_id:
			return
	# Set target
	current_target = target
	ai.parent.unit_visual.set_target(target)
	# Que attack command if attack moving
	if ai.state == "Attack_move" or "Idle":
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
		
func switch_target_aggro_check() -> bool:
	if (is_player_command() and ai.state == "Attack_move") or !is_player_command():
		if aggro_timer >= AGGRO_CHECK_INTERVAL:
			aggro_timer = 0.0
			var enemy = parent.unit_combat.closest_enemy_in_aggro_range()
			if is_valid_target(enemy) and should_switch_target(enemy):
				set_target(enemy)
				return true
	return false

func switch_target_to_attacker() -> bool:
	for unit in recent_attackers:
		var attacker: Node = unit["attacker"]
		if is_valid_target(attacker):
			if should_switch_target(attacker):
				set_target(attacker)
				return true
	return false

func advance_timers(delta):
	time_since_start += delta
	aggro_timer += delta
	attack_timer -= delta

func clean_recent_attackers():
	recent_attackers = recent_attackers.filter(
		func(record): return time_since_start - record["time"] < ATTACKER_MEMORY
	)


func on_attacked_by(attacker: Node) -> void:
	if attacker == null or !is_instance_valid(attacker) or attacker.unit_combat.dead:
		return

	recent_attackers.append({
		"attacker": attacker,
		"time": time_since_start
	})

func is_valid_target(target) -> bool:
	if target == null or !is_instance_valid(target) or target.unit_combat.dead:
		return false
	return true

func set_target_from_command() -> void:
	var cmd = ai.get_current_command()
	if cmd != {} and cmd.has("target_unit") and is_instance_valid(cmd.target_unit):
		set_target(cmd.target_unit, true)

func is_player_command() -> bool:
	var cmd = ai.command_handler.current_command
	return cmd.is_player_command if cmd.has("is_player_command") else false

func clear_combat_state():
	ai.parent.unit_visual.clear_target()
	current_target = null
	is_attack_committed = false
	has_attacked = false
	attack_anim_timer = 0.0
	recent_attackers.clear()
