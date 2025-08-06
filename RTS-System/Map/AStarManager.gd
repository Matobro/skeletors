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
	print("Cell coords:", start_cell)
	start_cell = _get_nearest_free_cell(start_pos)

	var end_cell: Vector2

	# Handle targeting unit
	if target_unit != null:
		var target_cell = grid_manager._get_cell_coords(target_unit.global_position)
		var found_valid_adjacent = false

		# Offsets around target cell
		var offsets = [
			Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0),  # Cardinal
			Vector2(1, 1), Vector2(1, -1), Vector2(-1, -1), Vector2(-1, 1) # Diagonal
		]

		for offset in offsets:
			var neighbor = target_cell + offset
			var neighbor_id = grid_manager._get_cell_id(neighbor)

			if grid_manager._is_in_grid(neighbor) and astar.has_point(neighbor_id) and not grid.has(neighbor):
				end_cell = neighbor
				found_valid_adjacent = true
				break

		# Fallback to nearest free cell around unit if no adjacent available
		if not found_valid_adjacent:
			end_cell = _get_nearest_free_cell(end_pos)
	else:
		end_cell = _get_nearest_free_cell(end_pos)

	var start_id = grid_manager._get_cell_id(start_cell)
	print("Start point id:", start_id)
	print("Start point pos (AStar):", astar.get_point_position(start_id))
	var end_id = grid_manager._get_cell_id(end_cell)

	if not astar.has_point(start_id):
		print("Warning: start cell ", start_cell, " invalid")
		return PackedVector2Array()

	if not astar.has_point(end_id):
		print("Warning: end cell ", end_cell, " invalid")
		return PackedVector2Array()

	var raw_path = astar.get_id_path(start_id, end_id)
	var world_path = PackedVector2Array()

	for id in raw_path:
		var grid_pos = astar.get_point_position(id)
		
		var cell_x = floor(grid_pos.x / grid_manager.cell_size) - grid_manager.half_width
		var cell_y = floor(grid_pos.y / grid_manager.cell_size) - grid_manager.half_height
		print("Path cell:", Vector2(cell_x, cell_y))

		var world_pos = grid_pos - Vector2(grid_manager.half_width, grid_manager.half_height) * grid_manager.cell_size
		world_path.append(world_pos)

	if world_path.size() > 0:
		print("Path (to target or neighbor) generated: ", world_path)
		world_path[0] = start_pos
		return smooth_path(world_path)
	else:
		print("Couldn't find path")
		return PackedVector2Array()


func smooth_path(path: PackedVector2Array) -> PackedVector2Array:
	if path.size() <= 2:
		return path.duplicate()

	var smoothed = PackedVector2Array()
	var current_index = 0
	smoothed.append(path[current_index])  # Always start at the beginning

	while current_index < path.size() - 1:
		var found = false
		# Look as far ahead as possible
		for next_index in range(path.size() - 1, current_index, -1):
			if has_line_of_sight(path[current_index], path[next_index]):
				smoothed.append(path[next_index])
				current_index = next_index
				found = true
				break
		if not found:
			# Shouldn’t really happen unless something breaks
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

	for i in range(0, steps + 1, 1):
		var x = from_cell.x + step_x * i
		var y = from_cell.y + step_y * i
		var cell = Vector2(round(x), round(y))
		var id = grid_manager._get_cell_id(cell)

		# Check for static obstacles
		if not astar.has_point(id) or astar.is_point_disabled(id):
			return false

		# Check for dynamic units
		if grid.has(cell):
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

func get_units_around(position: Vector2, radius: float = 32.0) -> Array:
	var units_in_radius := []
	
	# Use your _get_cells_covered to get all cells overlapping the radius
	var cells = grid_manager._get_cells_covered(position, radius)
	
	for cell in cells:
		if not grid_manager._is_in_grid(cell):
			continue
		if not grid.has(cell):
			continue
		
		for unit in grid[cell]:
			# Only include units within the actual radius distance
			if position.distance_to(unit.global_position) <= radius:
				units_in_radius.append(unit)
	
	return units_in_radius
