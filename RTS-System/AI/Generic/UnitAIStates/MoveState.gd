extends UnitState

func enter_state():
	#SpatialGrid.deregister_unit(parent)
	parent.is_moving = true
	var scale = parent.get_stat("movement_speed") / 330.0
	var animation_speed = pow(scale, StatModifiers.movement_speed_animation_modifier)
	ai.animation_player.play_animation("walk", animation_speed)
func exit_state():
	ai.clear_unit_state()
	#SpatialGrid.register_unit(parent)
	SpatialGrid.update_unit_position(parent)
	parent.velocity = Vector2.ZERO
	ai.animation_player.stop()

func state_logic(delta):
	if ai.current_command == null:
		ai.set_state("Idle")
		return

	# Update grid position every frame
	SpatialGrid.update_unit_position(parent)
	
	# Request path if not already requested
	if ai.path.size() <= 0 and !ai.path_requested:
		ai.request_path(delta)
		return

	if ai.path_index >= ai.path.size():
		ai._process_next_command()
		
	# Follow the path if it exists
	if ai.path.size() > 0:
		ai._follow_path(delta)
