extends UnitState

const PATH_RECALC_THRESHOLD := 32

func enter_state():
	var scale = parent.data.get_stat("movement_speed") / 330.0
	var animation_speed = pow(scale, StatModifiers.movement_speed_animation_modifier)
	ai.animation_player.play_animation("walk", animation_speed)
	
	ai.combat_state.set_target_from_command()

func exit_state():
	ai.command_handler.clear()
	ai.animation_player.stop()

func state_logic(delta: float) -> void:
	var cmd: Dictionary = ai.get_current_command()
	if cmd == {}:
		print("empty")
		ai.command_handler.process_next_command()
		return
	
	var target_unit = ai.combat_state.current_target
	if target_unit == null:
		print("no target")
		ai.command_handler.process_next_command()
		return

	# Check if in attack range
	if parent.is_within_attack_range(target_unit.global_position):
		ai.set_state("Attack")
		return

	# Update command target pos
	cmd.target_position = target_unit.global_position

	# Check if target moved enough
	if ai.pathfinder.last_requested_target.distance_to(target_unit.global_position) > PATH_RECALC_THRESHOLD and !ai.pathfinder.path_requested:
		ai.pathfinder.last_requested_target = target_unit.global_position
		ai.pathfinder.request_path()

	# Nudge toward target if path ended but still out of range
	if ai.pathfinder.path_index >= ai.pathfinder.path.size() and !parent.is_within_attack_range(target_unit.global_position):
		var dir = (target_unit.global_position - parent.global_position).normalized()
		parent.velocity = dir * parent.data.get_stat("movement_speed")
		parent.move_and_slide()
		parent.unit_visual.handle_orientation(dir)
	else:
		ai.pathfinder.follow_path(delta)
