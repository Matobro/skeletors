extends Node

var game_mode: String
var dev_mode: bool

func _ready():
	game_mode = "Skeletors"
	dev_mode = true

func start_game():
	if !multiplayer.is_server():
		return

	# Generate grid for pathfinding
	await MapHandler.setup_map()
	await SpatialGrid.build_map()

	# Spawn player
	if dev_mode:
		await PlayerManager.setup_player_manager(true)
	else:
		await PlayerManager.setup_player_manager(false)

	# Activate dev tools
	if dev_mode:
		var dev_unit_spawner = $"../World/DevSpawnUnit"
		dev_unit_spawner.init_node()

	# Do other stuff (start the game loop etc)

	LevelManager.start_game();
