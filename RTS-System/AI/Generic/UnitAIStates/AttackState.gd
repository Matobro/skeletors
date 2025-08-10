extends UnitState

func enter_state():
    #SpatialGrid.deregister_unit(parent)
    parent.velocity = Vector2.ZERO

func exit_state():
    ai.clear_unit_state()
    #SpatialGrid.register_unit(parent)

func state_logic(delta):
    var target_unit = ai.current_command.target_unit
    parent.attack_target = target_unit

    if target_unit == null or !is_instance_valid(target_unit) or target_unit.dead:
        handle_no_target()
        return

    if parent.is_attack_committed:
        process_attack_animation(delta, target_unit)
    else:
        try_to_attack(target_unit)

func process_attack_animation(delta, target_unit):
    parent.attack_anim_timer += delta

    var anim_speed = parent.get_stat("attack_speed")
    var attack_point_scaled = parent.data.unit_model_data.animation_attack_point / anim_speed
    var attack_duration_scaled = parent.data.unit_model_data.animation_attack_duration / anim_speed

    # Deal damage
    if not parent.has_attacked and parent.attack_anim_timer >= attack_point_scaled:
        parent.perform_attack()
        parent.has_attacked = true

    # Finish animation, start cooldown
    if parent.attack_anim_timer >= attack_duration_scaled:
        parent.attack_anim_timer = 0.0
        parent.has_attacked = false
        parent.is_attack_committed = false
        parent.attack_timer = parent.get_attack_delay()  # cooldown starts after animation ends


func try_to_attack(target_unit):
    if parent.attack_timer > 0.0:
        parent.attack_timer -= get_process_delta_time()
        return

    # Check if in range
    if parent.is_within_attack_range(target_unit.position):
        parent.velocity = Vector2.ZERO
        parent.is_attack_committed = true
        parent.has_attacked = false
        parent.attack_anim_timer = 0.0

        # Play attack animation at correct speed
        ai.animation_library.play("animations/attack")
        ai.animation_library.speed_scale = parent.get_stat("attack_speed")
    else:
        ai.set_state("Aggro")

func handle_no_target():
    if ai.fallback_command != null:
        ai.current_command = ai.fallback_command
        ai.fallback_command = null
        if ai.current_command.type == "Attack_move":
            ai.set_state("Attack_move")
        else:
            ai._process_next_command()
    else:
        ai._process_next_command()