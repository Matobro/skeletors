extends Node

class_name CommandHolder

signal command_issued(command_type: String, target, position: Vector2, is_queued: bool)

@export var commands_data: CommandsData
var unit: Unit
var queue := [] ### command queue
var rally_points = []
var current_point = null

var max_commands: int = 5

func _on_command_completed(command_type, fallback_command):
	if command_type == "Attack":
		if fallback_command != null:
			insert_command_at_front(fallback_command)

func issue_command(command_type: String, target, position: Vector2, is_queued: bool, player_id: int, shared_path: PackedVector2Array = [], offset: Vector2 = Vector2.ZERO):
	if player_id != unit.owner_id:
		return

	var command = {
		"type": command_type,
		"target_unit": target,
		"target_position": position,
		"shared_path": shared_path,
		"offset": offset
	}

	if is_queued:
		if max_commands <= queue.size():
			return

		queue.append(command)

	else:
		clear_commands()
		queue.append(command)
		clear_rally_points()

	await get_tree().process_frame
	show_command_visual(command_type, position)
	add_rally_point(command_type, position, is_queued)
	emit_signal("command_issued", command_type, target, position, is_queued)

func remove_command(command):
	queue.erase(command)
	
func insert_command_at_front(command):
	queue.insert(0, command)

func add_rally_point(command_type: String, pos, is_queued):
	var rp = commands_data.command_object.instantiate()
	rp.global_position = pos
	rally_points.append(rp)
	add_child(rp)
	if !is_queued:
		rp.init_node(commands_data.empty_command, false)
		return
	match command_type:
		"Move":
			rp.init_node(commands_data.rally_point, false)
		"Attack_move":
			rp.init_node(commands_data.attack_move_rally, false)
		_:
			rp.init_node(commands_data.rally_point, false)

func show_command_visual(command_type: String, target_pos: Vector2):
	var visual = commands_data.command_object.instantiate()
	add_child(visual)
	visual.global_position = target_pos

	var sprite_frames: SpriteFrames
	if command_type == "Move":
		sprite_frames = commands_data.move_command
	elif command_type == "Attack_move":
		sprite_frames = commands_data.attack_move_command
	else:
		sprite_frames = null

	visual.init_node(sprite_frames, true)

func get_next_command():
	if queue.size() > 0:
		return queue[0]
	return null

	#return queue.size() > 0 if queue[0] else null <-- why does this throw warning.. fkn gay syntax

func pop_next_command():
	if queue.size() > 0:
		queue.pop_front()
		pop_rally_point()


func clear_commands():
	current_point = null
	queue.clear()

func pop_rally_point():
	if rally_points.size() > 0:
		if current_point == null:
			current_point = 1
			return
		var rally = rally_points.pop_front()
		if is_instance_valid(rally):
			rally.queue_free()

func clear_rally_points():
	if rally_points.size() > 0:
		for rally_point in rally_points:
			if rally_point:
				rally_point.queue_free()
		rally_points.clear()
