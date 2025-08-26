extends Node
class_name UnitCommandHandler

signal command_completed(command_type: String, fallback_command)

var ai
var holder
var current_command = {}
var dont_clear := false
var fallback_command = {}

func _init(unit_ai, command_holder):
	ai = unit_ai
	holder = command_holder
	holder.command_issued.connect(_on_command_issued)
	command_completed.connect(holder._on_command_completed)

func _on_command_issued(_command_type, _target, _position, is_queued: bool, _is_player_command) -> void:
	if !is_queued:
		clear() # clears pathfinding
		ai.combat_state.clear_combat_state() # clears combat stuff
		process_next_command()

func process_next_command() -> void:
	if ai.parent.data.unit_type == "neutral":
		return

	dont_clear = false
	var next_command = holder.get_next_command()

	# If no next command go idle
	if next_command == {}:
		ai.set_state("Idle")
		return

	# Prevent spam commands
	if _is_spam(next_command):
		dont_clear = true
		holder.remove_command(next_command)
		return

	# Signal previous command as completed
	if current_command != {}:
		emit_signal("command_completed", current_command.type, fallback_command)

	# Advance queue
	current_command = next_command
	holder.pop_next_command()

	# Tell AI which state to enter
	_apply_command(current_command)

func clear() -> void:
	if dont_clear: # for spam protection
		return

	ai.pathfinder.reset()
	ai.animation_player.stop()

func _apply_command(cmd: Dictionary) -> void:
	var target_state := "Idle"

	match cmd.type:
		"Move":
			target_state = "Move"
		"Attack":
			target_state = "Attack"
		"Attack_move":
			target_state = "Attack_move"
		"Stop":
			target_state = "Stop"
		"Hold":
			target_state = "Hold"
		"GiveItem":
			target_state = "Move"
		"DropItem":
			target_state = "Move"
		"PickUpItem":
			target_state = "Move"
		_:
			target_state = "Idle"

	if ai.state != target_state:
		ai.set_state(target_state)

func _is_spam(next_command: Dictionary) -> bool:
	if next_command != {} and current_command != {}:
		if next_command.type == current_command.type:
			# Attack to different unit is never spam
			if next_command.type == "Attack":
				if next_command.has("target_unit") and current_command.has("target_unit"):
					if next_command.target_unit != current_command.target_unit:
						return false

			# Same type and close position = spam
			if next_command.has("target_position") and current_command.has("target_position"):
				if next_command.target_position.distance_to(current_command.target_position) <= 50:
					return true
	return false
