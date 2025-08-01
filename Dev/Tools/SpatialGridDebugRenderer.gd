extends Node2D

const DRAW_INTERVAL = 0.2

var draw_time = 0.0

var last_debug: bool

func _process(delta: float):
	if last_debug != SpatialGrid.debug_draw_enabled:
		queue_redraw()

	last_debug = SpatialGrid.debug_draw_enabled
	if draw_time > 0:
		draw_time -= delta
		return
	
	if SpatialGrid.debug_draw_enabled:
		draw_time = DRAW_INTERVAL
		queue_redraw()

func _draw():
	if !SpatialGrid.debug_draw_enabled:
		return

	var grid_width = SpatialGrid.grid_width
	var grid_height = SpatialGrid.grid_height
	var cell_size = SpatialGrid.cell_size
	var half_width = SpatialGrid.half_width
	var half_height = SpatialGrid.half_height
	var grid = SpatialGrid.grid
	var units = SpatialGrid.units
	
	print("DRAWINNNNG")
	var grid_pixel_size = Vector2(grid_width, grid_height) * cell_size

	# Draw grid border around center (0,0)
	var top_left = Vector2(-half_width, -half_height) * cell_size
	draw_rect(Rect2(top_left, grid_pixel_size), Color(0.7, 0.7, 0.7, 1), false, 2)
	
	# Draw only occupied cells
	for cell in grid.keys():
		if grid[cell].size() > 0:
			var pos = cell * cell_size 
			draw_rect(Rect2(pos, Vector2(cell_size, cell_size)), Color(1, 0, 0, 0.4))
	
	# Draw units centers
	for unit in units:
		draw_circle(unit.global_position, 5, Color.YELLOW)