extends Node

var game_mode: String
var dev_mode: bool

var units_loaded = false
var items_loaded = false
var start_requested = false

func _ready():
	game_mode = "Skeletors"
	dev_mode = true

func on_unit_database_loaded():
	units_loaded = true
	_check_ready_to_start()

func on_item_database_loaded():
	items_loaded = true
	_check_ready_to_start()

func _check_ready_to_start():
	if start_requested and units_loaded and items_loaded:
		start_game()

## Entry point for game, this is called when GameScene.tscn or TestScene is started
func request_start_game(test_mode):
	start_requested = true
	dev_mode = test_mode
	_check_ready_to_start()

func start_game():
	if !multiplayer.is_server():
		return

	# Setup essential shit (map, players, maybe later spawn 'doodads' like trees etc)

	# Generate grid for pathfinding
	await MapHandler.setup_map()
	await SpatialGrid.build_map()

	# Spawn player
	if dev_mode:
		PlayerManager.setup_player_manager(true)
	else:
		PlayerManager.setup_player_manager(false)

	# Activate dev tools
	if dev_mode:
		var dev_unit_spawner = $"../World/DevSpawnUnit"
		dev_unit_spawner.init_node()

	# Do other stuff (start the game loop etc)

	# replace with the new system
	WaveSystem.setup()
	WaveSystem.start_next_wave()
	#