extends UnitState

var ability_to_cast: BaseAbility
var ability_to_cast_index: int
var ability_target: Unit
var arrived: bool = false

var target_position
var target_unit

func enter_state():
	var cmd = ai.get_current_command()
	target_position = cmd["target_position"]
	target_unit = cmd["target_unit"]
	ability_to_cast_index = cmd["ability_index"]
	ability_to_cast = parent.unit_ability_manager.abilities[ability_to_cast_index]

	if ability_to_cast == null:
		exit_state()

func exit_state():
	ai.command_handler.clear()
	parent.velocity = Vector2.ZERO

func state_logic(delta):
	if ai.get_current_command() == {}:
		ai.set_state("Idle")
		return

	if parent.global_position.distance_to(target_position) <= ability_to_cast.ability_data.cast_range:
		on_arrival()
	else:
		ai.pathfinder.follow_path(delta)

func on_arrival():
	ai.animation_player.play_animation("casting", 1.0)
	if(!arrived):
		var ability = ability_to_cast
		ability.connect("cast_done", Callable(self, "on_cast_finished"), CONNECT_ONE_SHOT)
		arrived = true
		parent.unit_ability_manager.cast_ability(ability_to_cast_index, target_position, target_unit)
		
func on_cast_finished():
	ability_to_cast = null
	ability_to_cast_index = -1
	ability_target = null
	arrived = false
	target_position = null
	target_unit = null

	ai.animation_player.play_animation("idle", 1.0)
	ai.command_handler.process_next_command()
