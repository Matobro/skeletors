extends UnitState

func enter_state():
	parent.velocity = Vector2.ZERO
	ai.animation_player.play("idle")

func exit_state():
	ai.command_handler.clear()

func state_logic(_delta):
	pass
