extends UnitState

func enter_state():
	parent.velocity = Vector2.ZERO
	ai.command_handler.process_next_command()
	ai.animation_player.stop()

func exit_state():
	ai.command_handler.clear()

func state_logic(_delta):
	ai.command_handler.process_next_command()
