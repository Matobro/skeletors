extends Node

var path_queue := []

var astar_manager
var unit_manager
var grid_manager

signal path_ready(unit, path: PackedVector2Array, request_id)

func queue_unit_for_path(unit, request_id, target_unit = null):
	var start_pos = unit.global_position
	var end_pos = unit.state_machine.current_command.target_position if unit.state_machine.current_command != null else start_pos

	var last = unit.get_meta("last_requested_path") if unit.has_meta("last_requested_path") else {"start": Vector2.INF, "end": Vector2.INF}

	if last["start"].distance_to(start_pos) < 8 and last["end"].distance_to(end_pos) < 8:
		print("Skipping path request due to close start/end")
		return  # Same path -> skip

	unit.set_meta("last_requested_path", {"start": start_pos, "end": end_pos})

	for item in path_queue:
		if item.unit == unit:
			item.request_id = request_id
			return
	path_queue.append({
		"unit": unit, 
		"request_id": request_id, 
		"target_unit": target_unit
		})

func _process(_delta):
	var count = 0
	var max_this_frame = 10 if Engine.get_frames_per_second() > 55 else 2 
	while count < max_this_frame and path_queue.size() > 0:
		var item = path_queue.pop_front()
		var unit = item.unit
		var target_unit = item.target_unit
		var request_id = item.request_id
		var start_pos = unit.global_position
		var end_pos = unit.state_machine.current_command.target_position if unit.state_machine.current_command != null else start_pos
		var path = astar_manager.find_path(start_pos, end_pos, target_unit)
		if path.size() > 1 and path [0].distance_to(unit.global_position) > grid_manager.cell_size * 0.5:
			path.remove_at(0)
		emit_signal("path_ready", unit, path, request_id)
		count += 1
