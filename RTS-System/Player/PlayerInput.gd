extends Node2D

class_name PlayerInput

class MouseEventInfo:
	var pos: Vector2
	var total_units: int
	var click_target: Unit
	var is_queued: bool
	var attack_moving: bool

	static func create(_pos, _total_units, _click_target, _is_queued, _attack_moving) -> MouseEventInfo:
		var inst = MouseEventInfo.new()
		inst.pos = _pos
		inst.total_units = _total_units
		inst.click_target = _click_target
		inst.is_queued = _is_queued
		inst.attack_moving = _attack_moving
		return inst

@export var commands: CommandsData
@onready var selection_box = $"../CanvasLayer/BoxSelection"
@onready var player = get_parent()

var dev_disable_input: bool = false
var is_local_player: bool = false
var is_input_enabled: bool = false
var fullscreen: bool = true

var dragging = false

var player_id = null
var command_cooldown_frames := 0
var block_input_frames: int = 0

var drag_start = Vector2.ZERO

const DOUBLE_CLICK_TIME = 0.3
const DRAG_THRESHOLD := 50.0
const COMMAND_COOLDOWN := 10

var player_ui = null
var camera = null
var input_handler: PlayerInputHandler
var command_issuer: PlayerCommandIssuer
var selection_manager: SelectionManager

func init_node() -> void:
	if !player.is_local_player:
		is_input_enabled = false
		return
	
	is_input_enabled = true
	player_id = player.player_id
	camera = player.player_camera
	player_ui = player.player_ui

	selection_manager = SelectionManager.new(self, player_ui, player_id)
	command_issuer = PlayerCommandIssuer.new(self, selection_manager, player_id)
	input_handler = PlayerInputHandler.new(self, command_issuer, selection_manager, player_ui)

func _process(delta):
	if block_input_frames > 0:
		block_input_frames -= 1

	if command_cooldown_frames > 0:
		command_cooldown_frames -= 1

	if !is_input_enabled:
		selection_box.visible = false
		return
	
	if input_handler.multi_select_timer > 0:
		input_handler.multi_select_timer -= delta
	selection_manager.cleanup_invalid_units()

func _unhandled_input(event: InputEvent):
	if !is_input_enabled:
		return

	if block_input_frames > 0:
		return
		
	if event is InputEventKey and event.pressed:
		handle_keyboard_commands(event)
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		handle_mouse_input(event)

func get_key_event_info() -> MouseEventInfo:
	return MouseEventInfo.create(
			Vector2.ZERO,
			selection_manager.selected_units.size(),
			null,
			Input.is_key_pressed(KEY_SHIFT),
			Input.is_action_pressed("a")
		)
func get_mouse_event_info() -> MouseEventInfo:
		return MouseEventInfo.create(
			get_global_mouse_position(),
			selection_manager.selected_units.size(),
			check_click_hit(get_global_mouse_position()),
			Input.is_key_pressed(KEY_SHIFT),
			Input.is_action_pressed("a")
		)

func handle_keyboard_commands(event: InputEventKey):
	if event.is_action_pressed("8"):
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2(1920, 1080))
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen = !fullscreen
	elif event.is_action_pressed("s"):
		command_issuer.issue_stop_command(get_key_event_info())
	elif event.is_action_pressed("h"):
		command_issuer.issue_hold_command(get_key_event_info())
	elif event.is_action_pressed("i"):
		player_ui.shop_ui.visible = !player_ui.shop_ui.visible
	elif selection_manager.selected_units.size() > 0:
		match event.keycode:
			KEY_Q:
				selection_manager.selected_units[0].unit_ability_manager.cast_ability(0, get_global_mouse_position(), get_tree().current_scene)
			KEY_W:
				selection_manager.selected_units[0].unit_ability_manager.cast_ability(1, get_global_mouse_position(), get_tree().current_scene)
			KEY_E:
				selection_manager.selected_units[0].unit_ability_manager.cast_ability(2, get_global_mouse_position(), get_tree().current_scene)
				
func handle_mouse_input(event):
	if !is_input_enabled:
		return
	
	if block_input_frames > 0:
		return

	if command_cooldown_frames > 0:
		return

	if is_mouse_over_ui():
		dragging = false
		selection_box.visible = false
		selection_box.size = Vector2.ZERO
		return

	var event_info = get_mouse_event_info()
	
	input_handler.input_received(event, event_info)

func is_mouse_over_ui() -> bool:
	return get_viewport().gui_get_hovered_control() != null

func start_drag():
	dragging = true
	selection_box.visible = true

	selection_box.position = world_to_screen(drag_start)
	selection_box.size = Vector2.ZERO
	
func update_drag(current_pos: Vector2):
	var start_screen_pos = world_to_screen(drag_start)
	var current_screen_pos = world_to_screen(current_pos)
	var top_left = Vector2(
		min(start_screen_pos.x, current_screen_pos.x),
		min(start_screen_pos.y, current_screen_pos.y)
	)
	var size = (current_screen_pos - start_screen_pos).abs()
	
	selection_box.global_position = top_left
	selection_box.size = size
	
func end_drag(shift):
	dragging = false
	selection_box.visible = false
	
	selection_manager.select_units_in_box(Rect2(selection_box.global_position, selection_box.size), shift)

func world_to_screen(world_pos: Vector2) -> Vector2:
	var cam_pos = camera.global_position
	var zoom = camera.zoom
	var screen_center = camera.get_viewport_rect().size / 2
	return screen_center + (world_pos - cam_pos) * zoom

func check_click_hit(mouse_pos: Vector2):
	var space_state = get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = 30.0
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, mouse_pos)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query, 10)
	
	if results.size() > 0:
		var collider = results[0].collider
		if collider and collider.unit_visual and collider.unit_visual.has_method("set_selected"):
			return collider
			
	return null
