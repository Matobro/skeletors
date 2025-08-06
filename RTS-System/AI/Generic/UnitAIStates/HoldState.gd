extends UnitState

func enter_state():
    SpatialGrid.update_unit_position(parent)
    parent.velocity = Vector2.ZERO
    ai.animation_player.play("idle")
    parent.is_holding_position = true

func exit_state():
    parent.is_holding_position = false

func state_logic(_delta):
    pass