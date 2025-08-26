extends Node

var game_mode: String
var dev_mode: bool

func _ready():
    game_mode = "Skeletors"
    dev_mode = true

func start_game():
    MapHandler.setup_map()
    SpatialGrid.build_map()
    if multiplayer.is_server():
        PlayerManager.setup_player_manager()
        WaveSystem.setup()