extends Node

var unit_scenes = {
	UnitDatabase.UnitType.HERO: preload("res://RTS-System/Entities/Data/Hero.tscn"),
	UnitDatabase.UnitType.UNIT: preload("res://RTS-System/Entities/Data/Unit.tscn")
}

func create_unit(unit_data, player_id = 10) -> Unit:
	var scene = unit_scenes.get(unit_data.unit_type)
	var unit = scene.instantiate()
	unit.data = unit_data
	get_tree().current_scene.add_child(unit)
	unit.owner_id = player_id
	UnitHandler.register_unit(unit)

	return unit

func spawn(unit: Unit, pos: Vector2 = Vector2.ZERO) -> void:
	unit.global_position = get_spawn_point(pos)

func spawn_unit(unit_data: UnitData = null, pos: Vector2 = Vector2.ZERO, player_id = 10) -> Unit:
	var start_time := Time.get_ticks_usec()
	DevLogger.debug("Spawning unit for player %d " % player_id, "UnitSpawner")

	if unit_data == null:
		DevLogger.error("No UnitData in spawn_unit()", "UnitSpawner")
		return null

	if !unit_scenes.has(unit_data.unit_type):
		DevLogger.warn("Unknown unit_type ['%s'], reverting to default 'unit' scene" % unit_data.unit_type, "UnitSpawner")

	# Create unit
	var scene = unit_scenes.get(unit_data.unit_type, unit_scenes[UnitDatabase.UnitType.UNIT])
	var unit = scene.instantiate()

	if unit == null:
		DevLogger.error("Failed to instantiate unit ", "UnitSpawner")
		return null
	
	# Assign data
	unit.data = unit_data
	unit.owner_id = player_id
	unit.global_position = get_spawn_point(pos)

	var root = get_tree().current_scene
	root.add_child(unit)

	# Initialize unit
	unit.create_unit()

	# Add to registry
	UnitHandler.register_unit(unit)
	var elapsed := (Time.get_ticks_usec() - start_time) / 1000.0
	DevLogger.info("Spawned [%s] for player %d in %.2f ms" % [unit_data.name, player_id, elapsed], "UnitSpawner")

	return unit

func get_spawn_point(pos) -> Vector2:
	var desired_cell = SpatialGrid.grid_manager._get_cell_coords(pos)
	var free_cell = SpatialGrid.astar_manager._get_nearest_spawnable_cell(desired_cell)
	var spawn_pos = SpatialGrid.grid_manager.cell_center_to_world(free_cell)
	return spawn_pos
