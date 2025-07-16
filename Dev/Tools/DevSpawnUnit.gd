extends Node2D

var unit = preload("res://Entities/Units/Data/Unit.tscn")
var commandsData = preload("res://Commands/DefaultCommands.tres")

var spawning_unit: bool
var owner_id: int = 1
var mouse_pos = null
var temp_color: Color
var current_data = null

var unit_data_list: Array = []

@onready var unit_list = $"../CanvasLayer/DevBox/VBoxContainer/OptionButton"
@onready var spawn_button = $"../CanvasLayer/DevBox/VBoxContainer/Button"
@onready var spawn_visual = $"../CanvasLayer/TextureRect"
@onready var player_input = $"../PlayerObject/PlayerInput"
@onready var damage_text = $"../DamageTextPool"
@onready var owner_select = $"../CanvasLayer/DevBox/OptionButton"


func _ready():
	spawning_unit = false
	unit_data_list = load_units_from_folder("res://Entities/Units/Units/", "unit")
	unit_data_list += load_units_from_folder("res://Entities/Heroes/Heroes/", "hero")

	for data in unit_data_list:
		unit_list.add_item(data.name)

	for i in range(1, 13):
		owner_select.add_item(str(i))

	owner_select.item_selected.connect(_on_owner_id_selected)

	spawn_button.pressed.connect(_on_spawn_button_pressed)

func _process(_delta: float):
	mouse_pos = get_global_mouse_position()
	
	if spawning_unit:
		spawn_visual.position = mouse_pos
	
func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and spawning_unit:
			spawn_unit(current_data)
			
func spawn_unit(data):
	player_input.block_input_frames = 5
	var spawned_unit = unit.instantiate()
	spawned_unit.global_position = mouse_pos
	get_tree().current_scene.add_child(spawned_unit)
	spawned_unit.init_unit(data)
	spawned_unit.damage_text = damage_text
	spawned_unit.commands = commandsData
	spawned_unit.owner_id = owner_id
	player_input.selectable_units.append(spawned_unit)
	spawned_unit.died.connect(player_input._on_unit_died)
	show_unit_on_mouse(false)
	spawning_unit = false

func show_unit_on_mouse(value):
	spawn_visual.visible = value
	spawn_visual.texture = current_data.avatar

func load_units_from_folder(folder_path: String, unit_type: String) -> Array:
	var dir = DirAccess.open(folder_path)
	var units: Array = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".tres"):
				var unit_path = folder_path + "/" + file_name
				var _unit = load(unit_path)
				if _unit and _unit is UnitData and _unit.unit_type == unit_type:
					units.append(_unit)
			file_name = dir.get_next()
		dir.list_dir_end()
	return units

func _on_owner_id_selected(index):
	print("called")
	owner_id = index + 1

func _on_spawn_button_pressed():
	var selected_unit = unit_list.get_selected()
	if selected_unit < 0:
		return
	
	var selected_data = unit_data_list[selected_unit]
	current_data = selected_data
	spawning_unit = true
	show_unit_on_mouse(true)
