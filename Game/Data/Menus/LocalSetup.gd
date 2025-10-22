extends Node2D

var game_scene = preload("res://Game/Data/GameScene.tscn")

@onready var hero_info: HeroInfo = $CanvasLayer/HeroInfoPanel
@onready var buttons = {
	"start_button": $CanvasLayer/Buttons/StartButton
}

func _ready() -> void:
	buttons.start_button.connect("pressed", Callable(self, "on_start_pressed"))

func on_start_pressed():
	var selected_hero = hero_info.get_selected_hero()
	if selected_hero:
		var player_id = multiplayer.get_unique_id()
		print(player_id)
		NetworkManager.register_player(player_id, selected_hero)
		NetworkManager.start_singleplayer()
		get_tree().change_scene_to_packed(game_scene)
	else:
		print("No hero selected")
