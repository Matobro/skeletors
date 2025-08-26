extends Node2D

var game_scene = preload("res://Game/Data/GameScene.tscn")

@onready var hero_info: HeroInfo = $CanvasLayer/HeroInfoPanel
@onready var buttons = {
	"start_button": $CanvasLayer/Buttons/StartButton
}

func _ready() -> void:
	buttons.start_button.connect("pressed", Callable(self, "on_start_pressed"))

func on_start_pressed():
	var chosen_hero = hero_info.currently_selected
	if chosen_hero:
		var player_id = multiplayer.get_unique_id()
		print(player_id)
		NetworkManager.register_player(player_id, chosen_hero)
		NetworkManager.start_singleplayer()
		get_tree().change_scene_to_packed(game_scene)
	else:
		print("No hero selected")
