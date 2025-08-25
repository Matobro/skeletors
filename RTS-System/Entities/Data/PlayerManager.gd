extends Node

@onready var color_rect = $"../World/CanvasLayer/DevBox/ColorRect"
@onready var ai_text = $"../World/CanvasLayer/DevBox/ColorRect/Label"

var dev_spawner = null

var player_scene = preload("res://RTS-System/Player/PlayerObject.tscn")

var player_colors := {
	1: Color.GREEN,
	2: Color.BLUE,
	3: Color.SANDY_BROWN,
	4: Color.TEAL,
	5: Color.YELLOW,
	6: Color.ORANGE,
	7: Color.PURPLE,
	8: Color.GRAY,
	10: Color.RED
}
var players_to_spawn = [
	{ "id": 1, "is_ai": false, "hero": null },
	#{ "id": 10, "is_ai": true, "hero": null }
]

var players = {}

### INIT ###
func setup_player_manager() -> void:
	await get_tree().process_frame
	
	if GameManager.dev_mode == true:
		dev_spawner = get_node("/root/World/DevSpawnUnit")

	spawn_players()

	await get_tree().process_frame

	for player in get_all_players():
		print("Player ID: ", player.player_id, " created")
	
	if GameManager.dev_mode == true:
		dev_spawner.player_input = get_player(1).player_input
		dev_spawner.init_node()

### INIT END ###

### Player ###
func spawn_players():
	for player_data in players_to_spawn:
		var p = player_scene.instantiate()
		p.player_id = player_data.id
		p.is_ai = player_data.is_ai
		p.is_local_player = !player_data.is_ai and player_data.id == 1
		add_child(p)
		players[p.player_id] = p
		register_player(p)

func register_player(player_object):
	players[player_object.player_id] = player_object

func get_player_color(player_id: int) -> Color:
	return player_colors.get(player_id, Color.BLACK)

func get_player(player_id):
	return players.get(player_id)

func get_all_players():
	return players.values()

### Player End ###
