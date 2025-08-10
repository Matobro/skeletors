extends UnitState

func enter_state():
    ai.animation_player.play("idle")
    parent.velocity = Vector2.ZERO
    ai.aggro_check_timer = ai.AGGRO_CHECK_INTERVAL
    SpatialGridDebugRenderer._delete_path(parent)

func exit_state():
    ai.clear_unit_state()

func state_logic(delta):
    parent.velocity = Vector2.ZERO
    ai.aggro_check_timer += delta
    if ai.aggro_check_timer >= ai.AGGRO_CHECK_INTERVAL:
        ai.aggro_check_timer = 0.0
        var enemy = parent.closest_enemy_in_aggro_range()
        if enemy != null:
            parent.command_component.issue_command("Attack", enemy, enemy.global_position, false, parent.owner_id)