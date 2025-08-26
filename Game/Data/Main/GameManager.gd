extends Node

var game_mode: String
var dev_mode: bool

func _ready():
    game_mode = "Skeletors"
    dev_mode = true

    #start_game()

func start_game():
    MapHandler.setup_map()
    SpatialGrid.build_map()
    PlayerManager.setup_player_manager()
    WaveSystem.setup()