extends UnitState

func enter_state():
	SpatialGrid.deregister_unit(parent)
	parent.is_moving = true
	ai.animation_player.play("walk")

func exit_state():
	ai.clear_unit_state()
	SpatialGrid.register_unit(parent)
	parent.velocity = Vector2.ZERO
	ai.animation_player.stop()

func state_logic(delta):
	if ai.current_command == null:
		ai.set_state("Idle")
		return

	if ai.path.size() <= 0:
		ai.request_path()
		return

	ai._follow_path(delta)
