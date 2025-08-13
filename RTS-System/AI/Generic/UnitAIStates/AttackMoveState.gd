extends UnitState

func enter_state():
	SpatialGrid.deregister_unit(ai.parent)
	ai.aggro_check_timer = ai.AGGRO_CHECK_INTERVAL
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

	ai.aggro_check_timer += delta
	if ai.aggro_check_timer >= ai.AGGRO_CHECK_INTERVAL:
		ai.aggro_check_timer = 0.0
		var enemy = parent.closest_enemy_in_aggro_range()
		if enemy != null:
			if ai.fallback_command == null:
				ai.fallback_command = ai.current_command
			parent.command_component.insert_command_at_front({
				"type": "Attack",
				"target_unit": enemy,
				"target_position": enemy.global_position,
				"shared_path": [],
				"offset": Vector2.ZERO
			})
			ai.set_state("Aggro")
			return

	if ai.path.size() <= 0:
		ai.request_path(delta)
		return

	var distance_to_goal = parent.global_position.distance_to(ai.path[-1])

	if distance_to_goal < 10.0:
		ai._process_next_command()

	ai._follow_path(delta)
