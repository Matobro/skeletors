extends Node2D

var spawning_unit: bool
var owner_id: int = 1
var mouse_pos = null
var temp_color: Color
var current_data = null

var unit_data_list: Array = []
var owner_ids: Array = []

@onready var manager = null
@onready var unit_list = null
@onready var spawn_button = null
@onready var spawn_visual = null
@onready var player_input = null
@onready var owner_select = null
@onready var spawn_popup = null
@onready var nav_map = null

func init_node() -> void:
	if GameManager.dev_mode == false:
		return

	await get_tree().process_frame
	player_input = PlayerManager.get_player(1).player_input
	unit_list = $"../CanvasLayer/DevBox/VBoxContainer/OptionButton"
	spawn_button = $"../CanvasLayer/DevBox/VBoxContainer/Button"
	spawn_visual = $"../CanvasLayer/TextureRect"
	owner_select = $"../CanvasLayer/DevBox/OptionButton"
	spawn_popup = $"../CanvasLayer/SpawnPopUp"
	nav_map = $"../NavigationRegion2D"
	on_ready()

func on_ready():
	await get_tree().process_frame
	spawning_unit = false
	unit_data_list = UnitDatabase.units
	unit_data_list += UnitDatabase.heroes

	for data in unit_data_list:
		unit_list.add_item(data.name)

	for player in PlayerManager.get_all_players():
		owner_select.add_item("Player " + str(player.player_id))
		owner_ids.append(player.player_id)

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
	owner_id = owner_ids[index]
	current_data = unit_list.get_selected()

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
