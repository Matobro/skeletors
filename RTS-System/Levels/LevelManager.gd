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

func update():
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
		
		# All available enemy types for this level
		var available_enemies_data = UnitDatabase.get_unit_data().filter(
				func(u): return u.power_level <= level_number and u.is_spawnable_enemy
		)

		# Each level has 2 waves (you can make this dynamic later)
		var wave_count := 2

		for i in range(wave_count):
				var enemy_count := level_number * 2 # e.g. Level 5 → 15 enemies total in wave
				var wave_enemies: Array[Unit] = []

				for j in range(enemy_count):
						# Pick a random enemy from the available pool
						if available_enemies_data.is_empty():
								break
						var random_enemy_data = available_enemies_data.pick_random()

						var enemy: Unit = UnitSpawner.create_unit(random_enemy_data)
						wave_enemies.append(enemy)
						enemy.died.connect(_on_enemy_died)
				
				waves.append(Wave.new(wave_enemies))

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
		for enemy in wave.enemies:
				var spawn_point = get_tree().root.get_node("World/EnemySpawnPoints/East").global_position
				if is_instance_valid(enemy):
					# UnitSpawner.spawn(enemy, spawn_point)
					print("Spawned enemy: " + enemy.name, spawn_point)

func _on_enemy_died(enemy):
	# Defensive: remove the dead enemy from whichever wave actually contains it,
	# rather than assuming it's in the current_wave (avoids race condition).
	if not current_level:
		return
	for wave in current_level.waves:
		if wave.enemies.has(enemy):
			wave.remove_enemy(enemy)
			print("Removing enemy from wave: " + enemy.name)
			return
	print("Warning: died enemy not found in any wave: " + enemy.name)