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

func _on_command_issued(_command_type, _target, _position, is_queued: bool) -> void:
	if !is_queued:
		clear()
		ai.combat_state.clear()
		process_next_command()

func process_next_command() -> void:
	if ai.parent.data.unit_type == "neutral":
		return

	dont_clear = false
	var next_command = holder.get_next_command()

	# If no next command go idle
	if next_command == {}:
		# if ai.pathfinder.path.size() == 0 or ai.pathfinder.path_index >= ai.pathfinder.path.size():
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
	dont_clear = false

	# Tell AI which state to enter
	_apply_command(current_command)


func clear() -> void:
	if dont_clear: # for spam protection
		return

	ai.pathfinder.reset()
	ai.parent.attack_anim_timer = 0.0
	ai.parent.is_attack_committed = false
	ai.animation_player.stop()

func _apply_command(cmd: Dictionary) -> void:
	match cmd.type:
		"Move":
			ai.set_state("Move")
		"Attack":
			ai.set_state("Attack")
		"Attack_move":
			ai.set_state("Attack_move")
		"Stop":
			ai.set_state("Stop")
		"Hold":
			ai.set_state("Hold")
		_:
			ai.set_state("Idle")

func _is_spam(next_command: Dictionary) -> bool:
	if next_command != {} and current_command != {}:
		if next_command.type == current_command.type:
			if next_command.target_position.distance_to(current_command.target_position) <= 50:
				return true
	return false
