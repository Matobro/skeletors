extends UnitState

func enter_state() -> void:
	parent.velocity = Vector2.ZERO
	SpatialGridDebugRenderer._delete_path(parent)

func exit_state() -> void:
	ai.command_handler.clear()

func state_logic(delta: float) -> void:
	parent.velocity = Vector2.ZERO
	ai.animation_player.play_animation("idle", 1.0)

	var target = ai.combat_state.current_target
	if ai.combat_state.is_valid_target(target):
		ai.set_state("Attack")