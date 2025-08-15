extends UnitState

const PATH_RECALC_THRESHOLD := 32

func enter_state():
	SpatialGrid.deregister_unit(parent)
	var scale = parent.get_stat("movement_speed") / 330.0
	var animation_speed = pow(scale, StatModifiers.movement_speed_animation_modifier)
	ai.animation_player.play_animation("walk", animation_speed)
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
		ai.request_path(delta)
		return
	
	var target_pos = target_unit.global_position

	if ai.last_requested_target.distance_to(target_pos) > PATH_RECALC_THRESHOLD and !ai.path_requested:
		print("Request path")
		ai.last_requested_target = target_pos
		ai.request_path(delta)

	ai._follow_path(delta)

	# 'Nudge' towards target if reached goal but still out of range
	if ai.path_index >= ai.path.size() and !parent.is_within_attack_range(target_unit.global_position):
		var dir = (target_unit.global_position - parent.global_position).normalized()
		parent.velocity = dir * parent.get_stat("movement_speed")
		parent.move_and_slide()
		parent.handle_orientation(dir)
