extends Node2D

class_name Player
@onready var player_input = $"PlayerInput"
@onready var player_camera = $"PlayerCamera"
@onready var player_ui = $"CanvasLayer/PlayerUI"
@onready var tooltip_panel = $"CanvasLayer/PlayerUI/ToolTipPanel"

var player_id: int
var is_ai: bool
var hero: Hero = null
var is_local_player: bool = false

func _ready():
	if is_ai:
		if multiplayer.is_server():
			await get_tree().process_frame
			_setup_ai()
	else:
		if is_multiplayer_authority():
			await get_tree().process_frame
			_setup_human()
			UnitHandler.unit_died.connect(_on_unit_died)
			TooltipManager.register_player_tooltip(player_id, tooltip_panel)
	
func _setup_ai():
	player_ui.visible = false

	# attach ai logic
	var ai_controller = preload("res://RTS-System/AI/Generic/AI Player/AIController.gd").new()
	add_child(ai_controller)
	ai_controller.player = self
	
	setup_ai_script_for_mode(ai_controller)

func _setup_human():
	visible = true
	player_camera.enabled = true
	player_camera.make_current()
	player_ui.visible = true
	player_input.is_local_player = true
	player_input.init_node()
	player_ui.init_node(self)

func setup_ai_script_for_mode(ai_controller):
	var mode = GameManager.game_mode

	match mode:
		"Skeletors": 
			ai_controller.set_ai_script(preload("res://RTS-System/AI/Generic/AI Player/GameModeAIScripts/Skeletors.gd").new())
			print("AI script set to: ", mode)
		_:
			ai_controller.set_ai_script(null)
			push_warning("Game mode is invalid. AI disabled")
			
func get_local_player():
	return player_id

func _on_unit_died(unit):
	# player_ui.remove_unit_from_control(unit)
	pass
