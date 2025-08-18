extends UnitState

func enter_state() -> void:
	parent.velocity = Vector2.ZERO
	SpatialGridDebugRenderer._delete_path(parent)

func exit_state() -> void:
	ai.command_handler.clear()

func state_logic(delta: float) -> void:
	parent.velocity = Vector2.ZERO
	ai.animation_player.play_animation("idle", 1.0)

	ai.combat_state.update(delta)
