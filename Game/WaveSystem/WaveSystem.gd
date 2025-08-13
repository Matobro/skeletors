extends Node

var current_wave = 0
var wave_timer = 0.0

var spawn_keys = [] #holds spawn points, eg ["north", "east", "west"]
var spawn_index: int = 0

@onready var spawn_points = {
	"north": get_tree().root.get_node("World/EnemySpawnPoints/North"),
	"east": get_tree().root.get_node("World/EnemySpawnPoints/East"),
	"west": get_tree().root.get_node("World/EnemySpawnPoints/West")
}

func _ready():
	spawn_keys = spawn_points.keys()

### for dev
func _input(event: InputEvent):
	if event.is_action_pressed("p"):
		start_next_wave()

func start_next_wave():
	current_wave += 1
	var composition = get_wave_composition(current_wave)
	spawn_wave(composition)

func spawn_wave(composition):
	for enemy in composition:
		var spawn_point = get_next_spawn_point().global_position
		UnitSpawner.spawn_unit(enemy, spawn_point)
		await get_tree().create_timer(1.0).timeout

func get_next_spawn_point() -> Node2D:
	var key = spawn_keys[spawn_index]
	spawn_index = (spawn_index + 1) % spawn_keys.size()
	return spawn_points[key]

func get_wave_composition(wave: int) -> Array:
	var possible_enemies = UnitDatabase.get_enemy_units_for_wave(wave)
	var budget = 10 + wave * 5

	var composition = []

	while budget > 0 and possible_enemies.size() > 0:
		var enemy = possible_enemies[randi() % possible_enemies.size()]

		if enemy.power_level <= budget:
			composition.append(enemy)
			budget -= enemy.power_level
		else:
			possible_enemies.erase(enemy)

	print("Possible enemies for wave ", wave, " : ", possible_enemies.size())
	return composition
