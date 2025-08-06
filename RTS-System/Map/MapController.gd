extends Node2D

var grid_manager
var astar_manager
var unit_manager
var path_request_manager

var debug_draw_enabled: bool
var debug_grid_enabled: bool

func _ready():
	grid_manager = preload("res://RTS-System/Map/GridManager.gd").new()
	astar_manager = preload("res://RTS-System/Map/AStarManager.gd").new()
	unit_manager = preload("res://RTS-System/Map/UnitManager.gd").new()
	path_request_manager = preload("res://RTS-System/Map/PathRequestManager.gd").new()

	add_child(grid_manager)
	add_child(astar_manager)
	add_child(unit_manager)
	add_child(path_request_manager)

	astar_manager.grid_manager = grid_manager
	astar_manager.grid = unit_manager.grid
	unit_manager.grid_manager = grid_manager
	unit_manager.astar_manager = astar_manager
	path_request_manager.astar_manager = astar_manager
	path_request_manager.unit_manager = unit_manager
	path_request_manager.grid_manager = grid_manager

	astar_manager.build_astar_graph()

func find_path(start_pos: Vector2, end_pos: Vector2, target_unit = null) -> PackedVector2Array:
	return astar_manager.find_path(start_pos, end_pos, target_unit)

func register_unit(unit):
	unit_manager.register_unit(unit)

func deregister_unit(unit):
	unit_manager.deregister_unit(unit)

func update_unit_position(unit):
	unit_manager.update_unit_position(unit)

func queue_unit_for_path(unit, request_id, target_unit):
	path_request_manager.queue_unit_for_path(unit, request_id, target_unit)

func get_nearby_units(_position: Vector2, radius: float) -> Array:
	return unit_manager.get_nearby_units(_position, radius)

func get_cell_coords(pos) -> Vector2:
	return grid_manager._get_cell_coords(pos)

func get_units_around(_position: Vector2, radius: float = 32.0) -> Array:
	return astar_manager.get_units_around(_position, radius)

func get_debug_data() -> Dictionary:
	return {
		"grid_width": grid_manager.grid_width,
		"grid_height": grid_manager.grid_height,
		"cell_size": grid_manager.cell_size,
		"half_width": grid_manager.half_width,
		"half_height": grid_manager.half_height,
		"grid": unit_manager.grid,
		"units": unit_manager.units,
		"astar": astar_manager.astar
	}

func _input(_event):
	if Input.is_action_just_pressed("0"):
		debug_draw_enabled = !debug_draw_enabled
		print("Debug draw enabled: ", debug_draw_enabled)

	if Input.is_action_just_pressed("9"):
		debug_grid_enabled = !debug_grid_enabled
		print("Debug grid enabled: ", debug_grid_enabled)