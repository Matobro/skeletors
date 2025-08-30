extends UnitState

var ability_to_cast: BaseAbility
var ability_to_cast_index: int
var ability_target: Unit
var arrived: bool = false

var target_position
var target_unit

var command

signal cast_cancelled()

func enter_state():
	print("Entered casting state")

	command = ai.get_current_command()
	target_position = command["target_position"]
	target_unit = command["target_unit"]
	ability_to_cast_index = command["context"].index
	ability_to_cast = command["context"].ability

	if ability_to_cast == null:
		print("Ability to cast is null")
		exit_state()

	print("Casting: ", ability_to_cast)
	connect("cast_cancelled", Callable(ability_to_cast, "cancel_cast"), CONNECT_ONE_SHOT)

func exit_state():
	print("Exiting casting state")
	emit_signal("cast_cancelled")
	clear_state()
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
		print("Arrived at casting location")
		var ability = ability_to_cast
		ability.connect("cast_done", Callable(self, "on_cast_finished"), CONNECT_ONE_SHOT)
		arrived = true
		parent.unit_ability_manager.cast_ability(command["context"])

func clear_state():
	var ability = ability_to_cast
	if ability_to_cast != null and ability.is_connected("cast_done", Callable(self, "on_cast_finished")):
		ability.disconnect("cast_done", Callable(self, "on_cast_finished"))

	ability_to_cast = null
	ability_to_cast_index = -1
	ability_target = null
	arrived = false
	target_position = null
	target_unit = null
	ai.animation_player.play_animation("idle", 1.0)

func on_cast_finished():
	print("Cast finished")
	clear_state()

	ai.animation_player.play_animation("idle", 1.0)
	ai.command_handler.process_next_command()
