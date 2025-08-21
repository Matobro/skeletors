extends UnitState

const PATH_RECALC_THRESHOLD := 32

func enter_state():
	parent.velocity = Vector2.ZERO
	ai.combat_state.set_target_from_command()

func exit_state():
	ai.command_handler.clear()
	ai.animation_player.stop()

func state_logic(delta: float) -> void:
	# Update target tracking
	ai.combat_state.update(delta)
	var target_unit = ai.combat_state.current_target

	# No valid target
	if target_unit == null or !is_instance_valid(target_unit) or target_unit.unit_combat.dead:
		handle_no_target()
		return

	if target_unit == parent:
		return

	# If currently attacking
	if ai.combat_state.is_attack_committed:
		process_attack_animation(delta, target_unit)
	else:
		try_to_attack_or_follow(target_unit, delta)

func try_to_attack_or_follow(target_unit: Node, delta: float) -> void:
	# Attack if in range and ready
	if ai.combat_state.attack_timer <= 0.0 and parent.unit_combat.is_within_attack_range(target_unit.global_position):
		start_attack(target_unit)
	else:
		# Move toward target using pathfinder
		follow_target(target_unit, delta)

func start_attack(target_unit: Node) -> void:
	ai.animation_player.stop()
	parent.velocity = Vector2.ZERO
	
	ai.combat_state.is_attack_committed = true
	ai.combat_state.has_attacked = false
	ai.combat_state.attack_anim_timer = 0.0

	var attack_speed = parent.get_stat("attack_speed")
	var anim_speed = 1.0 * attack_speed
	ai.animation_player.play_animation("attack", anim_speed)

	parent.unit_visual.handle_orientation(
		(target_unit.global_position - parent.global_position).normalized()
	)

func follow_target(target_unit: Node, delta: float) -> void:
	# Always update path if target moves or path finished
	if ai.pathfinder.path_index >= ai.pathfinder.path.size() or ai.pathfinder.last_requested_target.distance_to(target_unit.global_position) > parent.get_stat("attack_range") + PATH_RECALC_THRESHOLD:
		
		ai.pathfinder.last_requested_target = target_unit.global_position
		ai.command_handler.current_command.target_position = target_unit.global_position
		ai.pathfinder.request_path()
	
	# Nudge toward target if path ended but still out of range
	if ai.pathfinder.path_index >= ai.pathfinder.path.size() and !parent.unit_combat.is_within_attack_range(target_unit.global_position):
		var dir = (target_unit.global_position - parent.global_position).normalized()
		parent.velocity = dir * parent.get_stat("movement_speed")
		ai.animation_player.play_animation("walk", ai.pathfinder.get_walk_animation_speed())
		parent.move_and_slide()
		parent.unit_visual.handle_orientation(dir)

	if !parent.unit_combat.is_within_attack_range(target_unit.global_position):
		# Follow the current path
		ai.pathfinder.follow_path(delta)

func process_attack_animation(delta: float, target_unit: Node) -> void:
	ai.combat_state.attack_anim_timer += delta

	var spd = max(parent.get_stat("attack_speed"), 0.01)
	var base_len = parent.animation_player.get_animation_speed("attack")
	var point_frac = clamp(parent.data.unit_model_data.animation_attack_point, 0.0, 0.999)

	# Attack point and duration in seconds (scaled by speed)
	var attack_point_time = (base_len * point_frac) / spd
	var attack_end_time   = base_len / spd

	# Apply damage at the correct frame
	if !ai.combat_state.has_attacked and ai.combat_state.attack_anim_timer >= attack_point_time:
		if parent.data.is_ranged:
			spawn_projectile(target_unit)
		else:
			parent.unit_combat.perform_attack()
		ai.combat_state.has_attacked = true
		ai.combat_state.attack_timer = parent.unit_combat.get_attack_delay()

	# Unlock after animation ends
	if ai.combat_state.attack_anim_timer >= attack_end_time:
		ai.combat_state.attack_anim_timer = 0.0
		ai.combat_state.has_attacked = false
		ai.combat_state.is_attack_committed = false

func spawn_projectile(target_unit: Node) -> void:
	var projectile_scene = parent.data.unit_model_data.projectile_scene
	if projectile_scene == null:
		push_warning("Unit: ", parent.name, " doesn't have projectile set")
		return

	var projectile = projectile_scene.instantiate()
	projectile.global_position = parent.global_position
	projectile.target = target_unit
	projectile.speed = parent.data.unit_model_data.projectile_speed
	projectile.damage = parent.get_stat("attack_damage")
	projectile.owner_unit = parent
	projectile.homing = true

	parent.get_tree().current_scene.add_child(projectile)

func handle_no_target() -> void:
	ai.combat_state.current_target = null

	# Clear current command if it has a dead target
	if ai.command_handler.current_command != {}:
		var cmd = ai.command_handler.current_command
		if cmd.has("target_unit") and (cmd.target_unit == null or !is_instance_valid(cmd.target_unit) or cmd.target_unit.unit_combat.dead):
			ai.command_handler.current_command = {}  # <-- Clear it
			ai.command_handler.clear()              # Reset path, attack timers, etc.

	# Process fallback or next command
	if ai.command_handler.fallback_command != {}:
		var fb = ai.command_handler.fallback_command
		ai.command_handler.fallback_command = {}
		ai.command_handler.current_command = fb

		if fb.type == "Attack_move":
			ai.set_state("Attack_move")
			return
		else:
			ai.command_handler.process_next_command()
			return
	else:
		ai.command_handler.process_next_command()
		return
