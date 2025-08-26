extends Node2D

var local_setup_scene = preload("res://Game/Data/Menus/LocalSetup.tscn")

@onready var buttons = {
	"local_button": $CanvasLayer/Buttons/HBoxContainer/Local,
	"online_button": $CanvasLayer/Buttons/HBoxContainer/Online,
	"options_button": $CanvasLayer/Buttons/HBoxContainer/Options,
	"exit_button": $CanvasLayer/Buttons/HBoxContainer/Exit
}
func _ready() -> void:
	buttons.local_button.connect("pressed", Callable(self, "on_local_pressed"))
	buttons.online_button.connect("pressed", Callable(self, "on_online_pressed"))
	buttons.options_button.connect("pressed", Callable(self, "on_options_pressed"))
	buttons.exit_button.connect("pressed", Callable(self, "on_exit_pressed"))

	buttons.online_button.visible = false
	buttons.options_button.visible = false

func on_local_pressed():
	get_tree().change_scene_to_packed(local_setup_scene)

func on_online_pressed():
	pass

func on_options_pressed():
	pass

func on_exit_pressed():
	get_tree().quit()
