extends Node

@export var unit_scene: PackedScene;

var current_level: Level;

signal level_changed(new_level: Level)
signal wave_changed(new_wave: Wave)

func start_game():
	current_level = generate_level(1)
	print("Started " + describe_level(current_level))
	load_level(current_level)
	emit_signal("level_changed", current_level)
	# notify first wave
	emit_signal("wave_changed", current_level.get_current_wave())

func check_for_next_wave():
	if not current_level:
		return
	var wave = current_level.get_current_wave()
	if wave and wave.is_cleared():
		print("Wave cleared!")
		if not current_level.advance_wave():
			print("Level cleared!")
			next_level()
		else:
			print("Next wave: ", current_level.current_wave_index + 1)
			load_wave(current_level.get_current_wave())
			emit_signal("wave_changed", current_level.get_current_wave())

func next_level():
	var next_num = current_level.number + 1
	current_level = generate_level(next_num)
	load_level(current_level)
	print("Advanced to " + describe_level(current_level))
	emit_signal("level_changed", current_level)
	# notify first wave of the new level
	emit_signal("wave_changed", current_level.get_current_wave())

func generate_level(level_number: int) -> Level:
	var waves: Array[Wave] = []
	
	# Each level has 2 waves (you can make this dynamic later)
	var wave_count := 2

	for i in range(wave_count):
		var enemy_count := level_number * 2 # e.g. Level 5 → 10 enemies per wave
		waves.append(Wave.new(enemy_count))

	return Level.new(level_number, waves)

func describe_level(level: Level) -> String:
	return "Level %d (%d waves)" % [level.number, level.waves.size()]

func load_level(level: Level) -> void:
	if not level:
		return
	load_wave(level.get_current_wave())

# Spawn a single wave's enemies (extracted from previous load_level)
func load_wave(wave: Wave) -> void:
	if not wave:
			return
	# spawn wave.max_count units now, pick types from UnitDatabase at spawn-time
	var available_enemies_data = UnitDatabase.get_unit_data().filter(
			func(u): return u.power_level <= current_level.number and u.is_spawnable_enemy
	)
	for i in range(wave.max_count):
		if available_enemies_data.is_empty():
				print("No available enemy types to spawn")
				break
		var random_enemy_data = available_enemies_data.pick_random()
		# pick a random spawn point per unit
		var spawn_point = _get_random_spawn_point()
		# create + spawn the unit (spawn_unit returns the created instance)
		var unit = UnitSpawner.spawn_unit(random_enemy_data, spawn_point, 10)
		# track in the wave and connect death
		wave.add_enemy(unit)
		unit.died.connect(_on_enemy_died)
		print("Spawned enemy: " + unit.name, spawn_point)

func _on_enemy_died(enemy):
	# Defensive: remove the dead enemy from whichever wave actually contains it.
	if not current_level:
		return
	for wave in current_level.waves:
		if wave.enemies.has(enemy):
			wave.remove_enemy(enemy)
			print("Removing enemy from wave: " + enemy.name)
	
	check_for_next_wave();

func _get_random_spawn_point() -> Vector2:
	var spawn_points := {
	"north": get_tree().root.get_node("World/EnemySpawnPoints/North"),
	"east": get_tree().root.get_node("World/EnemySpawnPoints/East"),
	"west": get_tree().root.get_node("World/EnemySpawnPoints/West")
	}
	var keys = spawn_points.keys()
	var chosen = keys.pick_random()
	return spawn_points[chosen].global_position
