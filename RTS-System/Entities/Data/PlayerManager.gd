extends Node

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

var players_to_spawn: Array = []
var players: Dictionary = {}

func setup_player_manager() -> void:
	await get_tree().process_frame
	if multiplayer.is_server():
		# Add AI only on host
		players_to_spawn.append({ "id": 10, "is_ai": true, "hero": null })
		spawn_players()

func spawn_players():
	if not multiplayer.is_server():
		return

	for player_data in players_to_spawn:
		var p = player_scene.instantiate()
		p.player_id = player_data.id
		p.is_ai = player_data.is_ai
		p.is_local_player = !player_data.is_ai and p.player_id == multiplayer.get_unique_id()
		add_child(p)
		players[p.player_id] = p
		register_player(p)

		if player_data.hero:
			var spawn_pos = Vector2(0, 0) #todo
			var hero_unit = UnitSpawner.spawn_unit(player_data.hero, spawn_pos, p.player_id)
			p.hero = hero_unit

func register_player(player_object):
	players[player_object.player_id] = player_object
	
func get_player_color(player_id: int) -> Color:
	return player_colors.get(player_id, Color.BLACK)

func get_player(player_id):
	return players.get(player_id)

func get_all_players():
	return players.values()

### Player End ###
