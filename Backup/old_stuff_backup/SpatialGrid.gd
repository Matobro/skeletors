extends Node2D

const DIAGONALS = [Vector2(1,1), Vector2(-1,1), Vector2(1,-1), Vector2(-1,-1)]

var debug_paths := {}
var debug_cells := []

var grid := {}

var astar := AStar2D.new()

var grid_width: int = 100
var grid_height: int = 100
var cell_size: float = 50.0

var half_width = grid_width / 2
var half_height = grid_height / 2

var units = []
var path_queue = []

var max_paths_per_frame = 5

var debug_draw_enabled := false
var debug_grid_enabled := false

signal path_ready(unit, path: PackedVector2Array, request_id)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("0"):
		debug_draw_enabled = !debug_draw_enabled
		print("Debug draw enabled: ", debug_draw_enabled)

	if Input.is_action_just_pressed("9"):
		debug_grid_enabled = !debug_grid_enabled
		print("Debug grid enabled: ", debug_grid_enabled)
		
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
		var path = find_path(start_pos, end_pos, target_unit)
		if path.size() > 1 and path [0].distance_to(unit.global_position) > cell_size * 0.5:
			path.remove_at(0)
		emit_signal("path_ready", unit, path, request_id)
		count += 1

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

func _ready() -> void:
	build_astar_graph()

func build_astar_graph():
	astar.clear()

	# Add all valid cells as points
	for x in range(-int(half_width), int(half_width)):
		for y in range(-int(half_height), int(half_height)):
			var cell = Vector2(x, y)
			if not grid.has(cell) or grid[cell].size() == 0:
				var id = _get_cell_id(cell)
				astar.add_point(id, (cell + Vector2(half_width, half_height)) * cell_size)

	# Connect each point to neighbors
	for x in range(-int(half_width), int(half_width)):
		for y in range(-int(half_height), int(half_height)):
			var cell = Vector2(x, y)
			var id = _get_cell_id(cell)
			if astar.has_point(id):

				# 4 way
				for offset in [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]:
					var neighbor = cell + offset
					if _is_in_grid(neighbor):
						var neighbor_id = _get_cell_id(neighbor)
						if astar.has_point(neighbor_id):
							astar.connect_points(id, neighbor_id, false)

				# Diagonals
				for offset in DIAGONALS:
					var neighbor = cell + offset
					if not _is_in_grid(neighbor):
						continue
					var neighbor_id = _get_cell_id(neighbor)
					if not astar.has_point(neighbor_id):
						continue

					# Check side cells for corners
					var side1 = cell + Vector2(offset.x, 0)
					var side2 = cell + Vector2(0, offset.y)

					if astar.has_point(_get_cell_id(side1)) and astar.has_point(_get_cell_id(side2)):
						astar.connect_points(id, neighbor_id, false)

func find_path(start_pos: Vector2, end_pos: Vector2, target_unit = null) -> PackedVector2Array:
	print("Finding path...")
	var start_cell = _get_cell_coords(start_pos)
	var end_cell = _get_cell_coords(end_pos)
	
	start_cell = _get_nearest_free_cell(start_pos)
	var desired_end_cell = end_cell

	if target_unit != null and grid.has(desired_end_cell) and grid[desired_end_cell].has(target_unit):
		end_cell = desired_end_cell
	else:
		end_cell = _get_nearest_free_cell(end_pos)
	
	var start_id = _get_cell_id(start_cell)
	var end_id = _get_cell_id(end_cell)

	if not astar.has_point(start_id):
		print("Warning: start cell ", start_cell, " invalid")
		return PackedVector2Array()

	if not astar.has_point(end_id):
		print("Warning: end cell ", end_cell, " invalid")
		return PackedVector2Array()

	var was_disabled = false
	if target_unit != null and end_cell == desired_end_cell:
		if astar.has_point(end_id):
			was_disabled = astar.is_point_disabled(end_id)
			if was_disabled:
				astar.set_point_disabled(end_id, false)

	var raw_path = astar.get_id_path(start_id, end_id)
	var world_path = PackedVector2Array()

	for id in raw_path:
		var grid_pos = astar.get_point_position(id)
		var world_pos = grid_pos - Vector2(half_width, half_height) * cell_size
		world_path.append(world_pos)

	# Return smoothed path if needed
	if world_path.size() > 8 and start_pos.distance_to(end_pos) > 200:
		world_path = smooth_path(world_path)
	
	if world_path.size () > 0:
		print("Path generated: ", world_path)
		return world_path
	
	else:
		print("Couldn't find path")
		return PackedVector2Array()

func smooth_path(path: PackedVector2Array) -> PackedVector2Array:
	if path.size() <= 2:
		return path.duplicate()

	var smoothed = PackedVector2Array()
	var current_index = 0
	smoothed.append(path[current_index])

	while current_index < path.size() - 1:
		var next_index = path.size() - 1
		while next_index > current_index + 1:
			if has_line_of_sight(path[current_index], path[next_index]):
				break
			next_index -= 1
		current_index = next_index
		smoothed.append(path[current_index])

	return smoothed

func has_line_of_sight(from: Vector2, to: Vector2) -> bool:
	var from_cell = _get_cell_coords(from)
	var to_cell = _get_cell_coords(to)

	var delta = to_cell - from_cell
	var steps = int(max(abs(delta.x), abs(delta.y)))
	if steps == 0:
		return true

	var step_x = delta.x / steps
	var step_y = delta.y / steps

	for i in range(0, steps + 1, 2):
		var x = from_cell.x + step_x * i
		var y = from_cell.y + step_y * i
		var cell = Vector2(round(x), round(y))
		var id = _get_cell_id(cell)

		debug_cells.append(cell) #debuggy

		if not astar.has_point(id) or astar.is_point_disabled(id):
			return false

	return true

func register_unit(unit) -> void:
	if not units.has(unit):
		units.append(unit)
	var radius = 16.0
	var covered_cells = _get_cells_covered(unit.global_position, radius)
	for cell in covered_cells:
		if not grid.has(cell):
			grid[cell] = []
		grid[cell].append(unit)
	update_occupied_cells(covered_cells, true)
	unit.set_meta("grid_coords", covered_cells)

func deregister_unit(unit) -> void:
	if units.has(unit):
		units.erase(unit)
	var coords_list = unit.get_meta("grid_coords")
	if coords_list:
		for cell in coords_list:
			if grid.has(cell):
				grid[cell].erase(unit)
				if grid[cell].size() == 0:
					grid.erase(cell)
		update_occupied_cells(coords_list, false)

func update_occupied_cells(cells: Array, occupied: bool) -> void:
	for cell in cells:
		var id = _get_cell_id(cell)
		if not astar.has_point(id):
			continue

		if occupied:
			astar.set_point_weight_scale(id, 5.0)
			astar.set_point_disabled(id, true)
		else:
			astar.set_point_weight_scale(id, 1.0)
			astar.set_point_disabled(id, false)

			# Reconnect all valid neighbors
			for offset in [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]:
				var neighbor = cell + offset
				if _is_in_grid(neighbor):
					var neighbor_id = _get_cell_id(neighbor)
					if astar.has_point(neighbor_id) and not astar.are_points_connected(id, neighbor_id):
						astar.connect_points(id, neighbor_id, false)
						astar.connect_points(neighbor_id, id, false)

			# Diagonal neighbors (with corner cutting check)
			for offset in DIAGONALS:
				var neighbor = cell + offset
				if not _is_in_grid(neighbor):
					continue
				var neighbor_id = _get_cell_id(neighbor)
				if not astar.has_point(neighbor_id):
					continue

				# Check both adjacent sides must also be passable
				var side1 = cell + Vector2(offset.x, 0)
				var side2 = cell + Vector2(0, offset.y)
				if astar.has_point(_get_cell_id(side1)) and astar.has_point(_get_cell_id(side2)):
					if not astar.are_points_connected(id, neighbor_id):
						astar.connect_points(id, neighbor_id, false)
					if not astar.are_points_connected(neighbor_id, id):
						astar.connect_points(neighbor_id, id, false)


func update_unit_position(unit) -> void:
	var radius = unit.radius if unit.has_method("radius") else 16.0
	var old_coords = unit.get_meta("grid_coords")
	var new_coords = _get_cells_covered(unit.global_position, radius)
	if old_coords != new_coords:
		deregister_unit(unit)
		register_unit(unit)
	else:
		unit.set_meta("grid_coords", new_coords)

func get_nearby_units(_position: Vector2, radius: float) -> Array:
	var center = _get_cell_coords(_position)
	var search_radius = ceil(radius / cell_size)
	var nearby = []
	for dx in range(-search_radius, search_radius + 1):
		for dy in range(-search_radius, search_radius + 1):
			var cell = center + Vector2(dx, dy)
			if grid.has(cell):
				for unit in grid[cell]:
					if _position.distance_to(unit.global_position) <= radius:
						nearby.append(unit)
	return nearby

func _get_nearest_free_cell(pos: Vector2) -> Vector2:
	var center = _get_cell_coords(pos)
	var max_search = 10  # search radius
	for r in range(max_search):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var cell = center + Vector2(dx, dy)
				if _is_in_grid(cell) and astar.has_point(_get_cell_id(cell)) and not grid.has(cell):
					return cell
	return center  # fallback

func find_walkable_cell_near(pos: Vector2, max_radius := 2) -> Vector2:
	var center = _get_cell_coords(pos)
	for r in range(1, max_radius + 1):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if abs(dx) + abs(dy) != r:
					continue
				var cell = center + Vector2(dx, dy)
				if _is_in_grid(cell) and astar.has_point(_get_cell_id(cell)):
					return cell

	return center  # fallback

func cell_to_world(cell: Vector2) -> Vector2:
	return (cell + Vector2(half_width, half_height)) * cell_size - Vector2(half_width, half_height) * cell_size

func _get_cell_coords(_position: Vector2) -> Vector2:
	var half_grid_pixels = Vector2(grid_width, grid_height) * cell_size / 2
	var relative_pos = _position + half_grid_pixels
	return Vector2(floor(relative_pos.x / cell_size), floor(relative_pos.y / cell_size)) - Vector2(half_width, half_height)

func _get_cells_covered(_position: Vector2, radius: float) -> Array:
	# Returns all cells that a circle (pos, radius) covers
	var min_cell = _get_cell_coords(_position - Vector2(radius, radius))
	var max_cell = _get_cell_coords(_position + Vector2(radius, radius))
	var cells = []
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			cells.append(Vector2(x, y))
	return cells

func _get_cell_id(cell: Vector2) -> int:
	# convert to positive index
	var shifted_x = int(cell.x + half_width)
	var shifted_y = int(cell.y + half_height)
	return shifted_x + shifted_y * grid_width

func _is_in_grid(cell: Vector2) -> bool:
	return int(cell.x) >= -int(half_width) and int(cell.x) < int(half_width) and int(cell.y) >= -int(half_height) and int(cell.y) < int(half_height)
