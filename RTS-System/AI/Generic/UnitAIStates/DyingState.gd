extends UnitState

func enter_state():
	SpatialGrid.update_unit_position(parent)
	SpatialGrid.deregister_unit(parent)
	parent.set_physics_process(false)
	parent.set_collision_layer(0)
	parent.set_collision_mask(0)
	ai.animation_player.connect("animation_finished", Callable(ai, "_on_death_animation_finished"), CONNECT_ONE_SHOT)
	ai.animation_player.play_animation("dying", 1.0)

func exit_state():
	pass

func state_logic(_delta):
	pass
