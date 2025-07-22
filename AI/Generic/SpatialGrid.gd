extends Node

class_name SpatialGrid

@export var cell_size: float = 100.0
var grid = {}

func _ready():
	pass

func _get_cell_coords(position: Vector2) -> Vector2:
	return Vector2(floor(position.x / cell_size), floor(position.y / cell_size))

func register_unit(unit):
	var coords = _get_cell_coords(unit.global_position)
	if not grid.has(coords):
		grid[coords] = []
	grid[coords].append(unit)
	unit.set_meta("grid_coords", coords)

func deregister_unit(unit):
	var coords = unit.get_meta("grid_coords")
	if coords and grid.has(coords):
		grid[coords].erase(unit)
		if grid[coords].empty():
			grid.erase(coords)

func update_unit_position(unit):
	var old_coords = unit.get_meta("grid_coords")
	var new_coords = _get_cell_coords(unit.global_position)
	if old_coords != new_coords:
		deregister_unit(unit)
		register_unit(unit)
	else:
		unit.set_meta("grid_coords", new_coords)

func get_nearby_units(position: Vector2, radius: float) -> Array:
	var center_coords = _get_cell_coords(position)
	var search_radius = ceil(radius / cell_size)
	var nearby_units = []

	for dx in range(-search_radius, search_radius + 1):
		for dy in range(-search_radius, search_radius + 1):
			var coords = center_coords + Vector2(dx, dy)
			if grid.has(coords):
				for unit in grid[coords]:
					if position.distance_to(unit.global_position) <= radius:
						nearby_units.append(unit)
	return nearby_units
