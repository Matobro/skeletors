extends UnitState

func enter_state():
    parent.velocity = Vector2.ZERO
    ai.animation_player.play("idle")
    parent.is_holding_position = true

func exit_state():
    ai.clear_unit_state()
    parent.is_holding_position = false

func state_logic(_delta):
    pass