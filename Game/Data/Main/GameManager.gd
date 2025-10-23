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
		PlayerManager.setup_player_manager(false)
		LevelManager.start_game();
		# WaveSystem.setup()
		# WaveSystem.start_next_wave();
		var dev_tool = $"../World/DevSpawnUnit"
		dev_tool.init_node()
	else:
		if multiplayer.is_server():
			PlayerManager.setup_player_manager()
			LevelManager.start_game();
			# WaveSystem.setup()
