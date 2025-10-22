extends UnitState

var ability_to_cast: BaseAbility
var ability_to_cast_index: int
var ability_target: Unit
var arrived: bool = false
var is_casting: bool = false
var target_position
var target_unit

var command

signal cast_cancelled()

func enter_state():
	if is_casting and ability_to_cast != null:
		ability_to_cast.cancel_cast()
		clear_state()

	is_casting = false
	command = ai.get_current_command()
	target_position = command["target_position"]
	target_unit = command["target_unit"]
	ability_to_cast_index = command["context"].index
	ability_to_cast = command["context"].ability

	if ability_to_cast == null:
		print("Ability to cast is null")
		exit_state()
		return

	print("Casting: ", ability_to_cast)
	connect("cast_cancelled", Callable(ability_to_cast, "cancel_cast"), CONNECT_ONE_SHOT)

func exit_state():
	print("Exiting casting state")
	emit_signal("cast_cancelled")
	clear_state()
	ai.command_handler.clear()
	parent.velocity = Vector2.ZERO

func state_logic(delta):
	var current_command = ai.get_current_command()
	if current_command == {}:
		ai.set_state("Idle")
		return

	if current_command != command:
		exit_state()
		ai.set_state("CastAbility")
		return

	if ability_to_cast.ability_data.is_instant_cast or parent.global_position.distance_to(target_position) <= ability_to_cast.ability_data.cast_range:
		on_arrival()
	else:
		ai.pathfinder.follow_path(delta)

func on_arrival():
	var ability = ability_to_cast

	if(!arrived):
		print("Arrived at casting location")

		#Connect signal for ability
		ability.connect("cast_done", Callable(self, "on_cast_finished"), CONNECT_ONE_SHOT)
		arrived = true

		#Start 3-phase animation
		start_casting_animation(ability.ability_data.cast_time)

		#Start casting ability
		parent.unit_ability_manager.cast_ability(command["context"])

func start_casting_animation(cast_time: float):
	is_casting = true

	#Play casting-start
	print("Playing casting-start")
	ai.animation_player.play_animation("casting-start", 1)
	var start_duration = ai.animation_player.get_animation_speed("casting-start")
	await ai.animation_player.animation_finished
	if !is_casting: return

	#Play casting-loop
	print("Playing casting-loop")
	ai.animation_player.play_animation("casting-loop", 1)
	var buffer = ai.animation_player.get_animation_speed("casting-loop")
	await ai.get_tree().create_timer(max(0.0, cast_time - buffer - start_duration)).timeout
	if !is_casting: return

func clear_state():
	var ability = ability_to_cast
	if ability_to_cast != null and ability.is_connected("cast_done", Callable(self, "on_cast_finished")):
		ability.disconnect("cast_done", Callable(self, "on_cast_finished"))

	is_casting = false
	ability_to_cast = null
	ability_to_cast_index = -1
	ability_target = null
	arrived = false
	target_position = null
	target_unit = null
	ai.animation_player.play_animation("idle", 1.0)

func on_cast_finished():
	#Play casting-end
	print("Playing casting-end")
	ai.animation_player.play_animation("casting-end", 1)
	await ai.animation_player.animation_finished
	
	clear_state()
	print("Cast finished")

	ai.animation_player.play_animation("idle", 1.0)
	ai.command_handler.process_next_command()
