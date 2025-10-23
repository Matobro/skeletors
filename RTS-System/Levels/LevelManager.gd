extends Node

var current_level: Level;

signal level_changed(new_level: Level)
signal wave_changed(new_wave: Wave)

func start_game():
	current_level = generate_level(1)
	print("Started " + describe_level(current_level))
	_load_level(current_level);
	emit_signal("level_changed", current_level)

func update():
	# Call this periodically (e.g., every frame or after enemy deaths)
	var wave = current_level.get_current_wave()
	if wave and wave.is_cleared():
		print("Wave cleared!")
		if not current_level.advance_wave():
			print("Level cleared!")
			next_level()
		else:
			print("Next wave: ", current_level.current_wave_index + 1)
			emit_signal("wave_changed", current_level.get_current_wave())

func next_level():
	var next_num = current_level.number + 1
	current_level = generate_level(next_num)
	_load_level(current_level);
	print("Advanced to " + describe_level(current_level))
	emit_signal("level_changed", current_level)

func generate_level(level_number: int) -> Level:
	# For now, just generate dummy waves with empty enemies
	var waves: Array[Wave] = []
	var enemies = UnitDatabase.get_units().filter(func(u): return u.power_level <= level_number and u.is_spawnable_enemy)

	for i in range(2): # e.g., Hardcode 2 waves per level
		waves.append(Wave.new(enemies))
	return Level.new(level_number, waves)

func describe_level(level: Level) -> String:
	return "Level %d (%d waves)" % [level.number, level.waves.size()]

func _load_level(level: Level) -> void:
	var wave = level.get_current_wave()
	for enemy in wave.enemies:
		var spawn_point = get_tree().root.get_node("World/EnemySpawnPoints/East").global_position
		UnitSpawner.spawn_unit(enemy, spawn_point)
		print("Spawned enemy: " + enemy.name, spawn_point)