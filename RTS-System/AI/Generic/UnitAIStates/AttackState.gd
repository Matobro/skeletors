extends UnitState

const PATH_RECALC_THRESHOLD := 32

func enter_state():
	parent.velocity = Vector2.ZERO

func exit_state():
	reset_attack_state()
	ai.animation_player.stop()

func state_logic(delta: float) -> void:
	# Update combat state timers and target
	ai.combat_state.update(delta)
	var target_unit = ai.combat_state.current_target

	if target_unit == null or !is_instance_valid(target_unit) or target_unit.unit_combat.dead:
		handle_no_target()
		return

	# detect target switch
	if target_unit != ai.combat_state.current_target_previous:
		reset_attack_state()
	ai.combat_state.current_target_previous = target_unit

	# if attack is in progress, advance animation
	if ai.combat_state.is_attack_committed:
		ai.combat_state.attack_anim_timer += delta
		process_attack_animation(target_unit)
		return

	# check cooldown and range
	if ai.combat_state.attack_timer <= 0.0:
		if parent.unit_combat.is_within_attack_range(target_unit.global_position):
			start_attack(target_unit)
		else:
			follow_target(target_unit, delta)
	else:
		# follow target if out of range
		if not parent.unit_combat.is_within_attack_range(target_unit.global_position):
			follow_target(target_unit, delta)
		else:
			parent.unit_visual.handle_orientation(
				(target_unit.global_position - parent.global_position).normalized()
			)

# Reset attack state when switching target
func reset_attack_state():
	ai.combat_state.is_attack_committed = false
	ai.combat_state.has_attacked = false
	ai.combat_state.attack_anim_timer = 0.0

# Start attack animation and commit the attack
func start_attack(target_unit: Node) -> void:
	ai.animation_player.stop()
	parent.velocity = Vector2.ZERO

	ai.combat_state.is_attack_committed = true
	ai.combat_state.has_attacked = false
	ai.combat_state.attack_anim_timer = 0.0

	var attack_speed = max(parent.get_stat("attack_speed"), 0.01)
	ai.animation_player.play_animation("attack", attack_speed)

	parent.unit_visual.handle_orientation(
		(target_unit.global_position - parent.global_position).normalized()
	)

# Process attack animation: apply damage/projectile at correct frame
func process_attack_animation(target_unit: Node) -> void:
	var base_len = parent.animation_player.get_animation_speed("attack")
	var attack_point = clamp(parent.data.unit_model_data.animation_attack_point, 0.0, 0.999)
	var spd = max(parent.get_stat("attack_speed"), 0.01)
	var attack_point_time = (base_len * attack_point) / spd
	var attack_end_time = base_len / spd

	# Apply damage/projectile at attack point, only if target in range
	if not ai.combat_state.has_attacked and ai.combat_state.attack_anim_timer >= attack_point_time:
		if parent.data.is_ranged:
			spawn_projectile(target_unit)
		else:
			parent.unit_combat.perform_attack()
		ai.combat_state.has_attacked = true
		# Start cooldown
		ai.combat_state.attack_timer = parent.unit_combat.get_attack_delay()

	# Reset attack state after animation ends
	if ai.combat_state.attack_anim_timer >= attack_end_time:
		reset_attack_state()

# Move toward the target if out of range
func follow_target(target_unit: Node, delta: float):
	var distance = parent.global_position.distance_to(target_unit.global_position)
	if distance > parent.get_stat("attack_range"):
		# Recalculate path if needed
		if ai.pathfinder.path_index >= ai.pathfinder.path.size() or\
			ai.pathfinder.last_requested_target.distance_to(target_unit.global_position) > parent.get_stat("attack_range") + PATH_RECALC_THRESHOLD:

			ai.pathfinder.last_requested_target = target_unit.global_position
			ai.command_handler.current_command.target_position = target_unit.global_position
			ai.pathfinder.request_path()

		# Follow path if exists
		if ai.pathfinder.path_index < ai.pathfinder.path.size():
			ai.pathfinder.follow_path(delta)
		else:
			# Direct move if path not ready
			var dir = (target_unit.global_position - parent.global_position).normalized()
			parent.velocity = dir * parent.get_stat("movement_speed")
			parent.move_and_slide()
			parent.unit_visual.handle_orientation(dir)

func handle_no_target():
	ai.combat_state.clear_combat_state()
	var fallback_command = ai.command_handler.fallback_command
	if fallback_command != {} and fallback_command.type == "Attack_move":
		ai.command_handler.fallback_command = {}
		ai.set_state("Attack_move")
		return
		
	ai.command_handler.process_next_command()

func spawn_projectile(target_unit: Node):
	var projectile_scene = parent.data.unit_model_data.projectile_scene
	if projectile_scene == null:
		push_warning("Unit: ", parent.name, " has no projectile set")
		return

	var projectile = projectile_scene.instantiate()
	projectile.global_position = parent.global_position
	projectile.scale = parent.data.unit_model_data.projectile_size
	projectile.target = target_unit
	projectile.speed = parent.data.unit_model_data.projectile_speed
	projectile.damage = parent.get_stat("attack_damage")
	projectile.owner_unit = parent
	projectile.homing = true

	parent.get_tree().current_scene.add_child(projectile)
