extends Node

const grid_width: int = 100
const grid_height: int = 100
const cell_size: float = 50.0
const half_width: int = grid_width / 2
const half_height: int = grid_height / 2

func _get_cell_coords(_position: Vector2) -> Vector2:
	var half_grid_pixels = Vector2(grid_width, grid_height) * cell_size / 2
	var relative_pos = _position + half_grid_pixels
	return Vector2(floor(relative_pos.x / cell_size), floor(relative_pos.y / cell_size)) - Vector2(half_width, half_height)

func _get_cell_id(cell: Vector2) -> int:
	var shifted_x = int(cell.x + half_width)
	var shifted_y = int(cell.y + half_height)
	return shifted_x + shifted_y * grid_width

func _is_in_grid(cell: Vector2) -> bool:
	return int(cell.x) >= -int(half_width) and int(cell.x) < int(half_width) and int(cell.y) >= -int(half_height) and int(cell.y) < int(half_height)

func _get_cells_covered(_position: Vector2, radius_world_units: float) -> Array:
	var radius_in_cells = radius_world_units / cell_size
	
	var min_cell = _get_cell_coords(_position - Vector2(radius_in_cells, radius_in_cells) * cell_size)
	var max_cell = _get_cell_coords(_position + Vector2(radius_in_cells, radius_in_cells) * cell_size)

	var cells = []
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			cells.append(Vector2(x, y))
	return cells

func cell_to_world(cell: Vector2) -> Vector2:
	return cell * cell_size

func cell_center_to_world(cell: Vector2) -> Vector2:
	return cell * cell_size + Vector2(cell_size, cell_size) * 0.5

func world_to_cell(pos: Vector2) -> Vector2:
	return Vector2(floor(pos.x / cell_size), floor(pos.y / cell_size))