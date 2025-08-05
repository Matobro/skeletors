extends Node

var grid = {}
var units = []

var grid_manager
var astar_manager

func register_unit(unit) -> void:
	if not units.has(unit):
		units.append(unit)
	var radius = 16.0
	var covered_cells = grid_manager._get_cells_covered(unit.global_position, radius)
	for cell in covered_cells:
		if not grid.has(cell):
			grid[cell] = []
		grid[cell].append(unit)
	astar_manager.update_occupied_cells(covered_cells, true)
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
		astar_manager.update_occupied_cells(coords_list, false)

func update_unit_position(unit) -> void:
	var radius = unit.radius if unit.has_method("radius") else 16.0
	var old_coords = unit.get_meta("grid_coords")
	var new_coords = grid_manager._get_cells_covered(unit.global_position, radius)
	if old_coords != new_coords:
		deregister_unit(unit)
		register_unit(unit)
	else:
		unit.set_meta("grid_coords", new_coords)

func get_nearby_units(position: Vector2, radius: float) -> Array:
	var cells = grid_manager._get_cells_covered(position, radius)
	var nearby_units = []
	for cell in cells:
		if grid.has(cell):
			for unit in grid[cell]:
				if unit.global_position.distance_to(position) <= radius and not nearby_units.has(unit):
					nearby_units.append(unit)
	return nearby_units
