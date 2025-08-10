extends UnitState

func enter_state():
	SpatialGrid.deregister_unit(parent)
	ai.animation_player.play("walk")
	ai.last_requested_target = Vector2.INF
	

func exit_state():
	ai.clear_unit_state()
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
	
	if ai.path.size() > 0 and parent.global_position.distance_to(target_unit.global_position) < 75:
		var target_cells = SpatialGrid.grid_manager._get_cells_covered(target_unit.global_position, target_unit.unit_scale)
		var path_end_cell = SpatialGrid.get_cell_coords(ai.path[-1])
		var within_range = false

		for cell in target_cells:
			if cell.distance_to(path_end_cell) <= 1:
				within_range = true
				break

		if !within_range and !ai.path_requested:
			ai.request_path()

	ai._follow_path(delta)

	# 'Nudge' towards target if reached goal but still out of range
	if ai.path_index >= ai.path.size() and !parent.is_within_attack_range(target_unit.global_position):
		var dir = (target_unit.global_position - parent.global_position).normalized()
		parent.velocity = dir * parent.get_stat("movement_speed") * 0.5
		parent.move_and_slide()
		parent.handle_orientation(dir)
