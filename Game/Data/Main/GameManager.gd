extends Node

var game_mode: String
var dev_mode: bool

func _ready():
	game_mode = "Skeletors"
	dev_mode = true

func start_game():
	MapHandler.setup_map()
	SpatialGrid.build_map()
	if dev_mode:
		await PlayerManager.setup_player_manager(false)
		var dev_tool = $"../World/DevSpawnUnit"
		dev_tool.init_node()

		LevelManager.start_game();
	else:
		if multiplayer.is_server():
			PlayerManager.setup_player_manager()
			LevelManager.start_game();
