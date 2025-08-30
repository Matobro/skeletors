extends UnitState

func enter_state():
	ai.pathfinder.reset()

func exit_state():
	parent.velocity = Vector2.ZERO

func state_logic(delta):
	var target = ai.combat_state.current_target

	# If a valid target exists switch to attack
	if target != null and is_instance_valid(target) and !target.unit_combat.dead:
		ai.command_handler.fallback_command = ai.command_handler.current_command
		ai.get_current_command().is_player_command = false
		ai.combat_state.current_target_previous = target
		ai.set_state("Attack")
		return

	if ai.pathfinder.path.size() > 0 and ai.pathfinder.path_index >= ai.pathfinder.path.size():
		ai.command_handler.fallback_command = {}
		ai.command_handler.process_next_command()

	ai.pathfinder.follow_path(delta)
