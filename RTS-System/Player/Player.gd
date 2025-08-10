extends Node2D

@onready var player_input = $"PlayerInput"
@onready var player_camera = $"PlayerCamera"
@onready var player_ui = $"CanvasLayer/PlayerUI"
@onready var tooltip_panel = $"CanvasLayer/PlayerUI/ToolTipPanel"

var player_id: int
var hero: Hero = null
var is_local_player: bool = false

func _ready():
	await get_tree().process_frame

	UnitHandler.unit_died.connect(_on_unit_died)
	if get_local_player() == 1:
		is_local_player = true
	else:
		is_local_player = false
	
	if is_local_player:
		player_camera.enabled = true
		player_camera.make_current()
		player_ui.visible = true
		player_input.is_local_player = true
		player_input.init_node()
		player_ui.init_node()
	else:
		player_ui.visible = false
	
	player_ui.parent = self
	TooltipManager.register_player_tooltip(player_id, tooltip_panel)

func get_local_player():
	return player_id

func _on_unit_died(unit):
	player_ui.remove_unit_from_control(unit)
