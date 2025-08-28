extends Node2D

class_name InputReceiver

var player_id

var dragging: bool = false
var drag_start = Vector2.ZERO
var selection_box

const DRAG_THRESHOLD := 10

signal intent_issued(input_info: InputInfo)

func _init(player_id_ref: int) -> void:
	player_id = player_id_ref
	selection_box = $"../../CanvasLayer/SelectionBox"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)

func _handle_mouse_button(event):
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_left_click()
			else:
				_finish_left_click()
		MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_issue_right_click()

func _handle_mouse_motion(event):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if !dragging and event.relative.length() > DRAG_THRESHOLD:
			_start_drag()
		if dragging:
			_update_drag()

func _start_left_click():
	drag_start = get_global_mouse_position()
	dragging = false

func _finish_left_click():
	if dragging:
		_issue_box_select()
	else:
		_issue_single_select()

func _issue_right_click():
	var info := InputInfo.new()
	info.mouse_button = InputInfo.CursorButton.RIGHT
	info.clicked_position = get_global_mouse_position()
	info.clicked_unit = _get_unit_at(info.clicked_position)
	info.keys_pressed = _get_modifier_keys()
	emit_signal("intent_issued", info)

func _issue_single_select():
	var pos = get_global_mouse_position()
	var info := InputInfo.new()
	info.intent_type = InputInfo.IntentType.SELECT
	info.clicked_position = pos
	info.clicked_unit = _get_unit_at(pos)
	info.keys_pressed = _get_modifier_keys()
	emit_signal("intent_issued", info)

func _issue_box_select():
	var rect = _make_drag_rect(drag_start, get_global_mouse_position())
	var info := InputInfo.new()
	info.intent_type = InputInfo.IntentType.BOX_SELECT
	info.drag_rect = rect
	info.keys_pressed = _get_modifier_keys()
	emit_signal("intent_issued", info)
	selection_box.visible = false
	dragging = false

func _start_drag():
	dragging = true
	selection_box.visible = true

func _update_drag():
	var rect = _make_drag_rect(drag_start, get_global_mouse_position())
	selection_box.global_position = rect.position
	selection_box.size = rect.size

func _make_drag_rect(start: Vector2, end: Vector2) -> Rect2:
	var top_left = Vector2(min(start.x, end.x), min(start.y, end.y))
	var size = (end - start).abs()
	return Rect2(top_left, size)

func _get_modifier_keys() -> Array:
	var keys = []
	if Input.is_action_pressed("shift"): keys.append("shift")
	if Input.is_action_pressed("ctrl"): keys.append("ctrl")
	return keys

func _get_unit_at(mouse_pos: Vector2):
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
		if collider and collider.unit_combat and !collider.unit_combat.dead:
			return collider
			
	return null