extends Node2D

const DRAW_INTERVAL = 1.0
const GRID_INTERVAL = 1.0

var grid_time = 0.0
var draw_time = 0.0

var force_draw: bool
var last_debug: bool

var paths := {}

func _ready() -> void:
	z_index = 500

func _process(delta: float):
	if last_debug != SpatialGrid.debug_draw_enabled:
		queue_redraw()

	last_debug = SpatialGrid.debug_draw_enabled

	if grid_time > 0:
		grid_time -= delta

	if force_draw:
		force_draw = false
		draw_time = DRAW_INTERVAL
		queue_redraw()
		return

	if draw_time > 0:
		draw_time -= delta
		return
	
	draw_time = DRAW_INTERVAL
	if SpatialGrid.debug_draw_enabled:
		queue_redraw()

func _receive_path(unit, path):
	_delete_path(unit)
	await get_tree().process_frame
	paths[unit] = path
	force_draw = true
	queue_redraw()

func _delete_path(unit):
	if paths.has(unit):
		paths.erase(unit)

	queue_redraw()

func _draw():
	if !SpatialGrid.debug_draw_enabled:
		return

	var debug_data = SpatialGrid.get_debug_data()

	var grid_width = debug_data.grid_width
	var grid_height = debug_data.grid_height
	var cell_size = debug_data.cell_size
	var half_width = debug_data.half_width
	var half_height = debug_data.half_height
	var grid = debug_data.grid
	var units = debug_data.units
	var astar = debug_data.astar
	
	var grid_pixel_size = Vector2(grid_width, grid_height) * cell_size

	var top_left = Vector2(-half_width, -half_height) * cell_size

	# Draw grid border
	draw_rect(Rect2(top_left, grid_pixel_size), Color(0.7, 0.7, 0.7, 1), false, 2)

	# Draw grid center
	draw_circle(Vector2.ZERO, 10, Color.RED)

	# Draw cells
	for cell in grid.keys():
		if grid[cell].size() > 0:
			var pos = cell * cell_size
			draw_rect(Rect2(pos, Vector2(cell_size, cell_size)), Color(1, 0, 0, 0.4))

	# Draw unit bounds
	for unit in units:
		var radius = unit.unit_scale
		var pos = unit.global_position
		var _top_left = pos - Vector2(radius, radius)
		var size = Vector2(radius * 2, radius * 2)
		draw_rect(Rect2(_top_left, size), Color.GREEN, false)

	if SpatialGrid.debug_grid_enabled:
		var manager = PlayerManager
		var cam = manager.players[1].player_camera
		var screen_size = get_viewport().get_visible_rect().size
		var cam_pos = cam.global_position
		var zoom = cam.zoom
		var world_screen_size = screen_size / zoom
		var half_screen_size = world_screen_size * 0.5
		var visible_rect = Rect2(cam_pos - half_screen_size, world_screen_size)

		for id in astar.get_point_ids():
			var pos = astar.get_point_position(id)
			if visible_rect.has_point(pos):
				draw_circle(pos, 2, Color.GREEN)

			# for neighbor_id in astar.get_point_connections(id):
			# 	var neighbor_pos = astar.get_point_position(neighbor_id) + top_left
			# 	var line_rect = Rect2(pos, neighbor_pos - pos).abs()
			# 	if visible_rect.intersects(line_rect):
			# 		draw_line(pos, neighbor_pos, Color.GRAY)

	# Draw unit paths
	for unit in paths:
		if is_instance_valid(unit):
			var path = paths[unit]
			var color = Color.GREEN if unit.owner_id == 1 else Color.RED

			# Draw the full path only
			for i in range(path.size() - 1):
				draw_line(path[i], path[i + 1], color, 2.0)
