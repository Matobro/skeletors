extends Node

const DIAGONALS = [Vector2(1,1), Vector2(-1,1), Vector2(1,-1), Vector2(-1,-1)]

var astar := AStar2D.new()

var grid_manager
var grid = {}

func build_astar_graph():
	astar.clear()

	for x in range(-int(grid_manager.half_width), int(grid_manager.half_width)):
		for y in range(-int(grid_manager.half_height), int(grid_manager.half_height)):
			var cell = Vector2(x, y)
			if not grid.has(cell) or grid[cell].size() == 0:
				var id = grid_manager._get_cell_id(cell)
				astar.add_point(id, (cell + Vector2(grid_manager.half_width, grid_manager.half_height)) * grid_manager.cell_size)

	for x in range(-int(grid_manager.half_width), int(grid_manager.half_width)):
		for y in range(-int(grid_manager.half_height), int(grid_manager.half_height)):
			var cell = Vector2(x, y)
			var id = grid_manager._get_cell_id(cell)
			if astar.has_point(id):

				for offset in [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]:
					var neighbor = cell + offset
					if grid_manager._is_in_grid(neighbor):
						var neighbor_id = grid_manager._get_cell_id(neighbor)
						if astar.has_point(neighbor_id):
							astar.connect_points(id, neighbor_id, false)
				for offset in DIAGONALS:
					var neighbor = cell + offset
					if not grid_manager._is_in_grid(neighbor):
						continue
					var neighbor_id = grid_manager._get_cell_id(neighbor)
					if not astar.has_point(neighbor_id):
						continue

					var side1 = cell + Vector2(offset.x, 0)
					var side2 = cell + Vector2(0, offset.y)

					if astar.has_point(grid_manager._get_cell_id(side1)) and astar.has_point(grid_manager._get_cell_id(side2)):
						astar.connect_points(id, neighbor_id, false)

func update_occupied_cells(cells: Array, occupied: bool) -> void:
	for cell in cells:
		var id = grid_manager._get_cell_id(cell)
		if not astar.has_point(id):
			continue

		if occupied:
			astar.set_point_weight_scale(id, 5.0)
			astar.set_point_disabled(id, true)
		else:
			astar.set_point_weight_scale(id, 1.0)
			astar.set_point_disabled(id, false)

			for offset in [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]:
				var neighbor = cell + offset
				if grid_manager._is_in_grid(neighbor):
					var neighbor_id = grid_manager._get_cell_id(neighbor)
					if astar.has_point(neighbor_id) and not astar.are_points_connected(id, neighbor_id):
						astar.connect_points(id, neighbor_id, false)
						astar.connect_points(neighbor_id, id, false)

			for offset in DIAGONALS:
				var neighbor = cell + offset
				if not grid_manager._is_in_grid(neighbor):
					continue
				var neighbor_id = grid_manager._get_cell_id(neighbor)
				if not astar.has_point(neighbor_id):
					continue

				var side1 = cell + Vector2(offset.x, 0)
				var side2 = cell + Vector2(0, offset.y)
				if astar.has_point(grid_manager._get_cell_id(side1)) and astar.has_point(grid_manager._get_cell_id(side2)):
					if not astar.are_points_connected(id, neighbor_id):
						astar.connect_points(id, neighbor_id, false)
					if not astar.are_points_connected(neighbor_id, id):
						astar.connect_points(neighbor_id, id, false)

func find_path(start_pos: Vector2, end_pos: Vector2, target_unit = null) -> PackedVector2Array:
	print("Finding path...")
	var start_cell = grid_manager._get_cell_coords(start_pos)
	var end_cell = grid_manager._get_cell_coords(end_pos)
	
	start_cell = _get_nearest_free_cell(start_pos)
	var desired_end_cell = end_cell

	if target_unit != null and grid.has(desired_end_cell) and grid[desired_end_cell].has(target_unit):
		end_cell = desired_end_cell
	else:
		end_cell = _get_nearest_free_cell(end_pos)
	
	var start_id = grid_manager._get_cell_id(start_cell)
	var end_id = grid_manager._get_cell_id(end_cell)

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
		var world_pos = grid_pos - Vector2(grid_manager.half_width, grid_manager.half_height) * grid_manager.cell_size
		world_path.append(world_pos)

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
	var from_cell = grid_manager._get_cell_coords(from)
	var to_cell = grid_manager._get_cell_coords(to)

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
		var id = grid_manager._get_cell_id(cell)

		if not astar.has_point(id) or astar.is_point_disabled(id):
			return false

	return true

func _get_nearest_free_cell(pos: Vector2) -> Vector2:
	var center = grid_manager._get_cell_coords(pos)
	var max_search = 10  # search radius
	for r in range(max_search):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var cell = center + Vector2(dx, dy)
				if grid_manager._is_in_grid(cell) and astar.has_point(grid_manager._get_cell_id(cell)) and not grid.has(cell):
					return cell
	return center
