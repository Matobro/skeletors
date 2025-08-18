extends Node
class_name UnitCombatState

var ai
var parent

var current_target: Node = null
var aggro_timer: float = 0.0

const AGGRO_CHECK_INTERVAL := 0.25

func _init(_ai, _parent):
	ai = _ai
	parent = _parent

func clear():
	current_target = null
	aggro_timer = 0.0

func update(delta: float):
	aggro_timer += delta

	# check for new targets in range
	if aggro_timer >= AGGRO_CHECK_INTERVAL:
		aggro_timer = 0
		var enemy = parent.closest_enemy_in_aggro_range()
		if enemy != null and should_switch_target(enemy):
			set_target(enemy)

	# Validate current target
	if current_target != null and (!is_instance_valid(current_target) or current_target.dead):
		current_target = null
		
		if ai.command_handler.current_command != {} and ai.command_handler.current_command.type == "Attack":
			ai.command_handler.current_command = {}
			ai.command_handler.clear()
			ai.command_handler.process_next_command()


	# Check if target is unreachable
	if current_target != null and is_target_unreachable(current_target):
		var fallback = find_alternate_target()
		if fallback != null:
			set_target(fallback)

func set_target_from_command() -> void:
	var cmd = ai.get_current_command()
	if cmd != {} and cmd.has("target_unit") and is_instance_valid(cmd.target_unit):
		set_target(cmd.target_unit)

func should_switch_target(new_target: Node) -> bool:
	
	var cmd = ai.command_handler.current_command
	if cmd != {} and cmd.has("type") and cmd.type == "Attack" and cmd.has("target_unit") and cmd.target_unit != null:
		return false
	
	if current_target == null:
		return true
	var current_dist = parent.global_position.distance_to(current_target.global_position)
	var new_dist = parent.global_position.distance_to(new_target.global_position)
	return new_dist + 16 < current_dist

func set_target(target: Node) -> void:
	if target == null or !is_instance_valid(target) or target.dead:
		return

	current_target = target

	# Push new attack command in front of que
	parent.command_holder.insert_command_at_front({
		"type": "Attack",
		"target_unit": target,
		"target_position": target.global_position,
		"shared_path": [],
		"offset": Vector2.ZERO
	})

	ai.command_handler.process_next_command()

func is_target_unreachable(target: Node) -> bool:
	if parent.is_within_attack_range(target.global_position):
		return false
	# If path ended but still out of range-> unreachable
	if !ai.pathfinder.path_requested and ai.pathfinder.path_index >= ai.pathfinder.path.size():
		return parent.global_position.distance_to(target.global_position) > parent.get_stat("attack_range") + 64
	return false

func find_alternate_target() -> Node:
	# Find nearest reachable enemy
	var best: Node = null
	var best_dist = INF
	for e in parent.possible_targets:
		if e != current_target and !e.dead:
			var dist = parent.global_position.distance_to(e.global_position)
			if dist < best_dist:
				best_dist = dist
				best = e
	return best
