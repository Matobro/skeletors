extends UnitState

func enter_state():
	ai.pathfinder.reset()

func exit_state():
	ai.command_handler.clear()
	parent.velocity = Vector2.ZERO

func state_logic(delta: float) -> void:
	var cmd: Dictionary = ai.get_current_command()
	if cmd == null:
		ai.set_state("Idle")
		return

	ai.combat_state.update(delta)

	if ai.pathfinder.path.size() > 0 and ai.pathfinder.path_index >= ai.pathfinder.path.size():
		ai.command_handler.fallback_command = {}
		ai.command_handler.process_next_command()

	ai.pathfinder.follow_path(delta)
