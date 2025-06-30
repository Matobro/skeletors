extends Node2D

var unit = preload("res://Entities/Unit.tscn")
var unitdata = preload("res://Entities/Units/Test_Unit.tres")
var commandsData = preload("res://Commands/DefaultCommands.tres")

var spawning_unit: bool
var owner_id: int
var mouse_pos = null
var temp_color: Color

@onready var spawn_visual = $"../CanvasLayer/TextureRect"
#@onready var create_unit_button = $"../CanvasLayer/DevBox/CreateUnitButton"
#@onready var create_enemy_button = $"../CanvasLayer/DevBox/CreateEnemyButton"
@onready var player_input = $"../PlayerObject/PlayerInput"

func _ready():
	spawning_unit = false

func _process(delta: float):
	mouse_pos = get_global_mouse_position()
	
	if spawning_unit:
		spawn_visual.position = mouse_pos
	
func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and spawning_unit:
			spawn_unit()
			
func spawn_unit():
	var spawned_unit = unit.instantiate()
	spawned_unit.global_position = mouse_pos
	get_tree().current_scene.add_child(spawned_unit)
	spawned_unit.init_unit(unitdata)
	spawned_unit.commands = commandsData
	spawned_unit.owner_id = owner_id
	spawned_unit.color_tag.modulate = temp_color
	player_input.selectable_units.append(spawned_unit)
	show_unit_on_mouse(false)
	spawning_unit = false

func show_unit_on_mouse(value):
	spawn_visual.visible = value
	spawn_visual.texture = unitdata.avatar
	
func _on_create_unit_button_pressed():
	temp_color = Color(0.5, 2.0, 0.5)
	show_unit_on_mouse(true)
	spawning_unit = true
	owner_id = 1
	
func _on_create_enemy_button_pressed():
	temp_color = Color(2.0, 0.5, 0.5)
	show_unit_on_mouse(true)
	spawning_unit = true
	owner_id = 10
