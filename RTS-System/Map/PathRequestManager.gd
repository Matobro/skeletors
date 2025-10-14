extends Node

var path_queue := []

var astar_manager
var unit_manager
var grid_manager

const MAX_PATHS_PER_FRAME := 5
#const PATH_REQUEST_COOLDOWN := 100

signal path_ready(unit, path: PackedVector2Array, request_id)

## Queues a path generation for [unit] unless [request_id] already exists in queue. [target_unit] can be specified and it will be used in pathfinding
func queue_unit_for_path(unit, request_id, target_unit = null):
	#if !unit.has_meta("next_path_request_time"):
	#	unit.set_meta("next_path_request_time", 0)
	
	#var current_time = Time.get_ticks_msec()
	#if current_time < unit.get_meta("next_path_request_time"):
	#	return
		
	var unit_pathfinder = unit.unit_ai.pathfinder
	var unit_commands = unit.unit_ai.command_handler
	var start_pos = unit.global_position
	var end_pos = unit_commands.current_command.target_position if unit_commands.current_command != {} else start_pos

	var last = unit_pathfinder.last_requested_path
	
	if last != null and last.has("status") and last["status"] == "queued" and last["start"].distance_to(start_pos) < 30 and last["end"].distance_to(end_pos) < 30:
		print("Skipping path request due to path is almost same")
		return

	unit_pathfinder.last_requested_path = ({
		"start": start_pos, 
		"end": end_pos, 
		"status": "queued"
		})

	for item in path_queue:
		if item.unit == unit:
			item.request_id = request_id
			return

	#var delay = randi() % 50
	#unit.set_meta("next_path_request_time", current_time + PATH_REQUEST_COOLDOWN + delay)

	path_queue.append({
		"unit": unit,
		"request_id": request_id, 
		"target_unit": target_unit
		})
	print("Added path[", unit, " request id: ", request_id, " target: ", target_unit, "] to queue")
	return

func clear_path_requests_for_unit(unit):
	path_queue = path_queue.filter(func(item):
		return item.unit != unit
		)

func _process(_delta):
	var processed_count = 0
	while path_queue.size() > 0 and processed_count < MAX_PATHS_PER_FRAME:
		var item = path_queue.pop_front()
		var unit = item.unit
		if !is_instance_valid(unit):
			continue

		var target_unit = item.target_unit
		var request_id = item.request_id

		if target_unit != null and !is_instance_valid(target_unit):
			target_unit = null

		var start_pos = unit.global_position
		var end_pos = unit.unit_ai.command_handler.current_command.target_position if unit.unit_ai.command_handler.current_command != {} else start_pos
		var path = astar_manager.find_path(start_pos, end_pos, target_unit)
		emit_signal("path_ready", unit, path, request_id)

		processed_count += 1
