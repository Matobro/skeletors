extends Node

var unit_scenes = {
	"hero": preload("res://RTS-System/Entities/Data/Hero.tscn"),
	"unit": preload("res://RTS-System/Entities/Data/Unit.tscn")
}

func spawn_unit(unit_data: UnitData = null, pos: Vector2 = Vector2.ZERO, player_id = 10) -> Unit:

	# Create unit
	var scene = unit_scenes.get(unit_data.unit_type, unit_scenes["unit"])
	var unit = scene.instantiate()
	unit.data = unit_data
	unit.global_position = get_spawn_point(pos)
	get_tree().current_scene.add_child(unit)

	# Add to registry
	unit.owner_id = player_id
	UnitHandler.register_unit(unit)

	return unit

func get_spawn_point(pos) -> Vector2:
	var desired_cell = SpatialGrid.grid_manager._get_cell_coords(pos)
	var free_cell = SpatialGrid.astar_manager._get_nearest_spawnable_cell(desired_cell)
	var spawn_pos = SpatialGrid.grid_manager.cell_center_to_world(free_cell)
	return spawn_pos
