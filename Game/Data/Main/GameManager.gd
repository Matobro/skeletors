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
	# Setup essential shit (map, players, maybe later spawn 'doodads' like trees etc)

	# Generate grid for pathfinding
	await MapHandler.setup_map()
	await SpatialGrid.build_map()

	# Spawn players
	PlayerManager.setup_player_manager(false)

	# Activate dev tools
	if dev_mode:
		var dev_unit_spawner = $"../World/DevSpawnUnit"
		dev_unit_spawner.init_node()

	##########################################################
	# Worry about network shit when its time to implement it #
	# this is here for reminder how the shit works           #
	# else:													 #
	# 	if multiplayer.is_server():						     #
	# 		PlayerManager.setup_player_manager()			 #
	##########################################################

	# Do other stuff (start the game loop etc)

	# replace with the new system
	WaveSystem.setup()
	WaveSystem.start_next_wave()
	#