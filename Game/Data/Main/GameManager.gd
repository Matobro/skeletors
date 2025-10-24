extends Node

var game_mode: String
var dev_mode: bool

func _ready():
	game_mode = "Skeletors"
	dev_mode = true

func on_unit_database_loaded():
	start_game()

func on_item_database_loaded():
	## probably setup shop or something
	pass

func start_game():
	MapHandler.setup_map()
	SpatialGrid.build_map()
	if dev_mode:
		PlayerManager.setup_player_manager(false)
		WaveSystem.setup()
		WaveSystem.start_next_wave();
		var dev_tool = $"../World/DevSpawnUnit"
		dev_tool.init_node()
	else:
		if multiplayer.is_server():
			PlayerManager.setup_player_manager()
			WaveSystem.setup()
