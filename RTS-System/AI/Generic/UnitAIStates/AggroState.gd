extends UnitState

func enter_state():
	SpatialGrid.deregister_unit(parent)
	ai.animation_player.play("walk")
	ai.last_requested_target = Vector2.INF

func exit_state():
	ai.path = []
	ai.path_index = 0
	ai.path_requested = false
	ai.last_requested_target = Vector2.ZERO
	SpatialGrid.register_unit(parent)
	ai.animation_player.stop()

func state_logic(delta):
	var target_unit = ai.current_command.target_unit
	if target_unit == null or !is_instance_valid(target_unit) or target_unit.dead:
		ai._process_next_command()
		return

	if parent.is_within_attack_range(target_unit.global_position):
		ai.set_state("Attack")
		return

	ai.current_command.target_position = target_unit.global_position

	if ai.path.size() <= 0:
		ai.request_path()
		return

	ai._follow_path(delta)
	
	if ai.path.size() > 0:
		var target_cell = SpatialGrid.get_cell_coords(target_unit.global_position)
		var path_end_cell = SpatialGrid.get_cell_coords(ai.path[-1])
		if target_cell.distance_to(path_end_cell) > 1:
			ai.request_path()

	# 'Nudge' towards target if reached goal but still out of range
	if ai.path_index >= ai.path.size() and !parent.is_within_attack_range(target_unit.global_position):
		var dir = (target_unit.global_position - parent.global_position).normalized()
		parent.velocity = dir * parent.get_stat("movement_speed") * 0.5
		parent.move_and_slide()
		parent.handle_orientation(dir)
