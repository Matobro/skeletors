extends Node

@onready var dev_spawner = $"DevSpawnUnit"

var player_scene = preload("res://Player/PlayerObject.tscn")

var players_to_spawn = [
	{ "id": 1, "is_ai": false, "hero": null },
	{ "id": 10, "is_ai": true, "hero": null }
]

var players = {}

func _ready() -> void:
	spawn_players()
	await get_tree().process_frame
	dev_spawner.player_input = get_player(1).player_input
	dev_spawner.init_node()

func spawn_players():
	for player_data in players_to_spawn:
		var p = player_scene.instantiate()
		p.player_id = player_data.id
		add_child(p)
		players[p.player_id] = p
		register_player(p)

func register_player(player_object):
	players[player_object.player_id] = player_object

func get_player(player_id):
	return players.get(player_id)

func get_all_players():
	return players.values()

func _on_unit_died(unit):
	if unit.owner_id == 10:
		for player in get_all_players():
			if player.player_id != 10:
				player.hero.get_xp(unit.data.stats.xp_yield)
