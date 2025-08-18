extends UnitState

func enter_state():
	parent.is_moving = true

func exit_state():
	ai.command_handler.clear()
	parent.velocity = Vector2.ZERO

func state_logic(delta):
	if ai.get_current_command() == {}:
		ai.set_state("Idle")
		return

	if ai.pathfinder.path.size() > 0 and ai.pathfinder.path_index >= ai.pathfinder.path.size():
		ai.command_handler.process_next_command()
		
	ai.pathfinder.follow_path(delta)
