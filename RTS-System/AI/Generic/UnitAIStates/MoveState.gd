extends UnitState

func enter_state():
    ai.path = []
    SpatialGrid.deregister_unit(parent)
    parent.is_moving = true
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

    if ai.path.size() <= 0:
        ai.request_path()
        return

    ai._follow_path(delta)