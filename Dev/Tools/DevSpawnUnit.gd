extends Node2D

var unit_scenes = {
	"hero": preload("res://RTS-System/Entities/Data/Hero.tscn"),
	"unit": preload("res://RTS-System/Entities/Data/Unit.tscn")
}
var commandsData = preload("res://RTS-System/Commands/DefaultCommands.tres")

var spawning_unit: bool
var owner_id: int = 1
var mouse_pos = null
var temp_color: Color
var current_data = null

var unit_data_list: Array = []

@onready var manager = null
@onready var unit_list = null
@onready var spawn_button = null
@onready var spawn_visual = null
@onready var player_input = null
@onready var owner_select = null
@onready var spawn_popup = null
@onready var nav_map = null


func init_node() -> void:
	unit_list = $"../CanvasLayer/DevBox/VBoxContainer/OptionButton"
	spawn_button = $"../CanvasLayer/DevBox/VBoxContainer/Button"
	spawn_visual = $"../CanvasLayer/TextureRect"
	#player_input = $"../PlayerObject/PlayerInput"
	owner_select = $"../CanvasLayer/DevBox/OptionButton"
	spawn_popup = $"../CanvasLayer/SpawnPopUp"
	nav_map = $"../NavigationRegion2D"
	on_ready()

func on_ready():
	await get_tree().process_frame
	spawning_unit = false
	unit_data_list = UnitDatabase.unit_list
	unit_data_list += UnitDatabase.hero_list

	for data in unit_data_list:
		unit_list.add_item(data.name)

	for i in range(1, 11):
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
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and spawning_unit:
			finish_spawn()

			
func spawn_unit(data):
	if !PlayerManager.get_player(owner_id):
		push_warning("Player: ", owner_id, " does not exist")
		finish_spawn()
		return
	
	### Spawn unit ##
	UnitSpawner.spawn_unit(data, mouse_pos, owner_id)

func finish_spawn():
	spawn_popup.visible = false
	player_input.block_input_frames = 10
	show_unit_on_mouse(false)
	spawning_unit = false
	await get_tree().process_frame
	player_input.is_input_enabled = true

func show_unit_on_mouse(value):
	spawn_visual.visible = value
	spawn_visual.texture = current_data.avatar

func _on_owner_id_selected(index):
	owner_id = index + 1

func _on_spawn_button_pressed():
	var selected_unit = unit_list.get_selected()
	if selected_unit < 0:
		return
	
	var selected_data = unit_data_list[selected_unit]
	current_data = selected_data
	spawning_unit = true
	show_unit_on_mouse(true)
	spawn_popup.visible = true

	player_input.is_input_enabled = false
	player_input.block_input_frames = 0
