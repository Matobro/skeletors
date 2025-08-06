extends UnitState

func enter_state():
	SpatialGrid.deregister_unit(ai.parent)
	ai.aggro_check_timer = ai.AGGRO_CHECK_INTERVAL
	ai.animation_player.play("walk")

func exit_state():
	ai.path = []
	ai.path_index = 0
	ai.path_requested = false
	ai.last_requested_target = Vector2.ZERO
	SpatialGrid.register_unit(parent)
	parent.velocity = Vector2.ZERO
	ai.animation_player.stop()

func state_logic(delta):
	if ai.current_command == null:
		ai.set_state("Idle")
		return

	ai.aggro_check_timer += delta
	if ai.aggro_check_timer >= ai.AGGRO_CHECK_INTERVAL:
		ai.aggro_check_timer = 0.0
		var enemy = parent.closest_enemy_in_aggro_range()
		if enemy != null:
			ai.fallback_command = ai.current_command
			parent.command_component.issue_command("Attack", enemy, enemy.global_position, false, parent.owner_id)
			return

	if ai.path.size() <= 0:
		ai.request_path()
		return

	ai._follow_path(delta)
