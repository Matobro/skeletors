extends Node

const DIAGONALS = [Vector2(1,1), Vector2(-1,1), Vector2(1,-1), Vector2(-1,-1)]

var astar := AStar2D.new()

var grid_manager
var grid = {}
var occupied_cells := {}
var walkable_cells := []

func build_astar_graph():
	astar.clear()

	# Add points for all empty cells
	for cell in grid.keys():
		if grid[cell].size() == 0:
			var id = grid_manager._get_cell_id(cell)
			var pos = grid_manager.cell_center_to_world(cell)
			astar.add_point(id, pos)

	# Connect neighbors
	for cell in grid.keys():
		var id = grid_manager._get_cell_id(cell)
		if not astar.has_point(id):
			continue

		# Cardinal neighbors
		for offset in [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]:
			var neighbor = cell + offset
			if grid.has(neighbor) and astar.has_point(grid_manager._get_cell_id(neighbor)):
				var neighbor_id = grid_manager._get_cell_id(neighbor)
				astar.connect_points(id, neighbor_id, false)

		# Diagonal neighbors
		for offset in DIAGONALS:
			var neighbor = cell + offset
			if not grid.has(neighbor) or not astar.has_point(grid_manager._get_cell_id(neighbor)):
				continue

			var side1 = cell + Vector2(offset.x, 0)
			var side2 = cell + Vector2(0, offset.y)
			if astar.has_point(grid_manager._get_cell_id(side1)) and astar.has_point(grid_manager._get_cell_id(side2)):
				var neighbor_id = grid_manager._get_cell_id(neighbor)
				astar.connect_points(id, neighbor_id, false)

func build_walkable_cells():
	walkable_cells.clear()
	for cell in grid.keys():
		if not grid[cell] and astar.has_point(grid_manager._get_cell_id(cell)):
			walkable_cells.append(cell)

func update_occupied_cells(cells: Array, occupied: bool) -> void:
	for cell in cells:
		var id = grid_manager._get_cell_id(cell)
		if not astar.has_point(id):
			continue

		if occupied:
			# Disable point when a unit occupies it
			astar.set_point_weight_scale(id, 5.0)
			astar.set_point_disabled(id, true)
		else:
			# Free the point
			astar.set_point_weight_scale(id, 1.0)
			astar.set_point_disabled(id, false)

			# Reconnect cardinals (the popes)
			for offset in [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]:
				var neighbor = cell + offset
				if grid_manager._is_in_grid(neighbor):
					var neighbor_id = grid_manager._get_cell_id(neighbor)
					if astar.has_point(neighbor_id) and not astar.are_points_connected(id, neighbor_id):
						astar.connect_points(id, neighbor_id, false)
						astar.connect_points(neighbor_id, id, false)

			# Reconnect diagonals
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
	var start_cell = grid_manager._get_cell_coords(start_pos)
	var end_cell = grid_manager._get_cell_coords(target_unit.global_position if target_unit else end_pos)

	# Allow the target cell to be considered free (even if occupied by the target)
	end_cell = _get_nearest_reachable_free_cell(end_cell, start_cell)

	var start_id = grid_manager._get_cell_id(start_cell)
	var end_id = grid_manager._get_cell_id(end_cell)

	if not astar.has_point(start_id) or not astar.has_point(end_id):
		return PackedVector2Array()  # Path blocked

	var raw_path = astar.get_id_path(start_id, end_id)
	if raw_path.size() == 0:
		return PackedVector2Array()

	var world_path = PackedVector2Array()
	for id in raw_path:
		world_path.append(astar.get_point_position(id))

	# Start exactly at current position
	if world_path.size() > 0:
		world_path[0] = start_pos

	return smooth_path(world_path)



# Finds the nearest free tile that is reachable from start_cell
func _get_nearest_reachable_free_cell(target_cell: Vector2, start_cell: Vector2) -> Vector2:
	var visited := {}
	var queue := [target_cell]
	var distances := {}
	visited[target_cell] = true
	distances[target_cell] = target_cell.distance_to(start_cell)
	var start_id = grid_manager._get_cell_id(start_cell)

	while queue.size() > 0:
		# Pop the cell closest to the start
		queue.sort_custom(func(a,b):
			return int(distances[a] - distances[b])
		)
		var current = queue.pop_front()
		var current_id = grid_manager._get_cell_id(current)

		if _is_free_cell(current) and astar.has_point(current_id):
			if astar.get_id_path(start_id, current_id).size() > 0:
				return current

		for dir in [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1),
					Vector2(1,1), Vector2(-1,1), Vector2(1,-1), Vector2(-1,-1)]:
			var neighbor = current + dir
			if not grid_manager._is_in_grid(neighbor):
				continue
			if visited.has(neighbor):
				continue
			visited[neighbor] = true
			distances[neighbor] = neighbor.distance_to(start_cell)
			queue.append(neighbor)

	# fallback
	return start_cell


func _is_free_cell(cell: Vector2, ignore_unit=null) -> bool:
	if ignore_unit != null:
		if cell in occupied_cells and occupied_cells[cell] == ignore_unit:
			return true

	return grid.has(cell) and grid[cell].size() == 0 and not cell in occupied_cells



func smooth_path(path: PackedVector2Array) -> PackedVector2Array:
	if path.size() <= 2:
		return path.duplicate()

	var smoothed = PackedVector2Array()
	var current_index = 0
	smoothed.append(path[current_index])

	while current_index < path.size() - 1:
		var found = false
		for next_index in range(path.size() - 1, current_index, -1):
			if has_line_of_sight(path[current_index], path[next_index]):
				smoothed.append(path[next_index])
				current_index = next_index
				found = true
				break
		if not found:
			current_index += 1
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

	for i in range(0, steps + 1):
		var cell = Vector2(round(from_cell.x + step_x * i), round(from_cell.y + step_y * i))
		var id = grid_manager._get_cell_id(cell)

		if not astar.has_point(id) or astar.is_point_disabled(id):
			return false

		if grid.has(cell) and grid[cell].size() > 0:
			return false

	return true

func get_units_around(position: Vector2, radius: float = 32.0) -> Array:
	var units_in_radius := []
	var cells = grid_manager._get_cells_covered(position, radius)

	for cell in cells:
		if not grid_manager._is_in_grid(cell):
			continue
		if not grid.has(cell):
			continue

		for unit in grid[cell]:
			if position.distance_to(unit.global_position) <= radius:
				units_in_radius.append(unit)

	return units_in_radius
