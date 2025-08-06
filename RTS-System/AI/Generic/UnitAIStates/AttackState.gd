extends UnitState

func enter_state():
    SpatialGrid.deregister_unit(parent)
    parent.velocity = Vector2.ZERO

func exit_state():
    SpatialGrid.register_unit(parent)

func state_logic(delta):
    var target_unit = ai.current_command.target_unit
    parent.attack_target = target_unit

    # Check if target dead
    if target_unit == null or !is_instance_valid(target_unit) or target_unit.dead:
        if ai.fallback_command != null:
            ai.current_command = ai.fallback_command
            ai.fallback_command = null
            if ai.current_command.type == "Attack_move":
                ai.set_state("Attack_move")
            else:
                ai._process_next_command()
        else:
            ai._process_next_command()
        return

    # If is in middle of attack
    if parent.is_attack_committed:
        parent.attack_anim_timer += delta

        var anim_speed = parent.get_stat("attack_speed")
        var attack_point_scaled = parent.data.unit_model_data.animation_attack_point / anim_speed
        var attack_duration_scaled = parent.data.unit_model_data.animation_attack_duration / anim_speed

        # Deal damage 
        if !parent.has_attacked and parent.attack_anim_timer >= attack_point_scaled:
            parent.perform_attack()
            parent.has_attacked = true
        
        # Finish animation
        if parent.attack_anim_timer >= attack_duration_scaled:
            parent.attack_anim_timer = 0.0
            parent.has_attacked = false
            parent.is_attack_committed = false

    # Start new attack if not already attacking
    else:

        # Check range
        if parent.is_within_attack_range(target_unit.position):
            parent.velocity = Vector2.ZERO

            # Start new attack when out of cd
            if parent.attack_timer <= 0.0:
                parent.is_attack_committed = true
                parent.has_attacked = false
                parent.attack_anim_timer = 0.0
                parent.attack_timer = parent.get_attack_delay()
                ai.animation_player.stop()
                ai.animation_library.play("animations/attack")
                ai.animation_library.speed_scale = parent.get_stat("attack_speed") + 0.05
        
        # Chase if out of range
        else:
            ai.set_state("Aggro")