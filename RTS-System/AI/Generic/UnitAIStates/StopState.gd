extends UnitState

func enter_state():
    SpatialGrid.update_unit_position(parent)
    parent.velocity = Vector2.ZERO
    ai._process_next_command()
    ai.animation_player.stop()

func exit_state():
    ai.clear_unit_state()

func state_logic(_delta):
    pass