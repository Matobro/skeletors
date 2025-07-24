extends Node2D

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

var dev_disable_input: bool = false

var player_id = null
var drag_start = Vector2.ZERO
var dragging = false
var is_local_player: bool = false
var is_input_enabled: bool = false

var block_input_frames: int = 0
var selected_units: Array[Unit] = []
var selectable_units: Array[Unit] = []
const DRAG_THRESHOLD := 50.0

@onready var selection_box = $"../CanvasLayer/BoxSelection"
@onready var player = get_parent()

var player_ui = null
var camera = null

func init_node() -> void:
	if !player.is_local_player:
		is_input_enabled = false
		return
	
	is_input_enabled = true
	player_id = player.player_id
	camera = player.player_camera
	player_ui = player.player_ui

func _process(_delta):
	if block_input_frames > 0:
		block_input_frames -= 1

	if !is_input_enabled:
		selection_box.visible = false
		return

	cleanup_invalid_units()

func _unhandled_input(event: InputEvent):
	if !is_input_enabled:
		return

	if event is InputEventKey and event.pressed:
		handle_keyboard_commands(event)
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		handle_mouse_input(event)

func get_key_event_info() -> MouseEventInfo:
	return MouseEventInfo.create(
			Vector2.ZERO,
			selected_units.size(),
			null,
			Input.is_key_pressed(KEY_SHIFT),
			Input.is_action_pressed("a")
		)
func get_mouse_event_info() -> MouseEventInfo:
		return MouseEventInfo.create(
			get_global_mouse_position(),
			selected_units.size(),
			check_click_hit(get_global_mouse_position()),
			Input.is_key_pressed(KEY_SHIFT),
			Input.is_action_pressed("a")
		)

func handle_keyboard_commands(event: InputEventKey):
	if event.is_action_pressed("s"):
		issue_stop_command(get_key_event_info())
	elif event.is_action_pressed("h"):
		issue_hold_command(get_key_event_info())

func handle_mouse_input(event):
	if !is_input_enabled:
		return
	
	if block_input_frames > 0:
		return

	if is_mouse_over_ui():
		dragging = false
		selection_box.visible = false
		selection_box.size = Vector2.ZERO
		return

	var event_info = get_mouse_event_info()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				on_left_click_pressed(event_info)
			else:
				on_left_click_released(event_info)

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				on_right_click_pressed(event_info)
			else:
				on_right_click_released(event_info)

	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			on_mouse_drag(event_info)

func cleanup_invalid_units():
	selected_units = selected_units.filter(func(u): return u != null and !u.dead)

####################################################################################
## INPUT BEHAVIOUR GOES HERE                                                      ##
## notes:						                                                  ##
## event_info is custom data type (MouseEventInfo)							      ##
## you can access these here via event_info						                  ##
## its data: [variable: description}                                              ##
##                                                                                ##
##	pos: 			clicked position/mouse position                               ##         
##	total_units: 	units selected amount  										  ##
##	click_target: 	clicked-unit(false if no)	  							      ##
##  is_queued: 		if holding down shift, false if no							  ##
##  attack_moving:  if holding A, false if no									  ##
##																				  ##
####################################################################################
#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv#

func on_left_click_pressed(event_info):
	### Attack move if holding A
	drag_start = event_info.pos
	if event_info.total_units > 0 and event_info.attack_moving:
		if event_info.click_target and event_info.click_target.owner_id == 10:
			issue_attack_command(event_info)
		else:
			issue_attack_move_command(event_info)
		return

	### If not A moving: select clicked target
	elif event_info.click_target and !event_info.attack_moving:
		select_unit_at_mouse_pos(event_info.pos, event_info.is_queued)

func on_left_click_released(event_info):
	if event_info.attack_moving:
		return

	if dragging:
		end_drag(event_info.is_queued)

	### If not dragging and no click target the clear selection if not holding shift
	elif !event_info.click_target and !event_info.is_queued:
			for unit in selected_units:
				unit.set_selected(false)
			selected_units.clear()
			player_ui.clear_control_group()

func on_right_click_pressed(event_info):
	if event_info.attack_moving:
		issue_attack_command(event_info)
	elif event_info.click_target and event_info.click_target.owner_id == 10:
		issue_attack_command(event_info)
	else:
		issue_move_command(event_info)

func on_right_click_released(_event_info):
	pass

func on_mouse_drag(event_info):
	### IF not started yet, then start box selecting
	if !dragging:
		if event_info.pos.distance_to(drag_start) > DRAG_THRESHOLD:
			start_drag()

	### Update if draggin
	if dragging and !event_info.attack_moving:
		update_drag(event_info.pos)

func on_mouse_drag_end(event_info):
	if dragging:
		end_drag(event_info.is_queued)
	pass
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^#
####################################################################################
## INPUT BEHAVIOUR GOES HERE                                                      ##
##							                                                      ##
##							                                                      ##
##							                                                      ##
##							                                                      ##
##							                                                      ##
####################################################################################

func issue_stop_command(event_info):
	for unit in selected_units:
		unit.command_component.issue_command("Stop", event_info.click_target, event_info.pos, event_info.is_queued, player_id)

func issue_hold_command(event_info):
	for unit in selected_units:
		unit.command_component.issue_command("Hold", event_info.click_target, event_info.pos, event_info.is_queued, player_id)
	
func issue_attack_command(event_info):
	for unit in selected_units:
		unit.command_component.issue_command("Attack", event_info.click_target, event_info.pos, event_info.is_queued, player_id)
	
func issue_attack_move_command(event_info):
	var formation_positions = calculate_unit_formation(event_info.total_units, event_info.pos)
	for i in range(selected_units.size()):
		var unit = selected_units[i]
		var target_pos = formation_positions[i]
		unit.command_component.issue_command("Attack_move", event_info.click_target, target_pos, event_info.is_queued, player_id)

func issue_move_command(event_info):
	var formation_positions = calculate_unit_formation(event_info.total_units, event_info.pos)
	for i in range(selected_units.size()):
		var unit = selected_units[i]
		var target_pos = formation_positions[i]
		unit.command_component.issue_command("Move", event_info.click_target, target_pos, event_info.is_queued, player_id)

func calculate_unit_formation(total_units, pos):
	var unit_targets := []
	var spacing := 82.0
	var columns = int(ceil(sqrt(total_units)))
	var rows := int(ceil(total_units / float(columns)))
	
	var total_width = (columns - 1) * spacing
	var total_height = (rows - 1) * spacing
	
	for i in range(total_units):
		var row = float(i) / columns
		var column: int = i % columns
		
		var offset := Vector2(
			column * spacing - total_width / 2,
			row * spacing - total_height / 2
		)
		
		offset += Vector2(randf_range(-20, 20), randf_range(-20, 20))
		unit_targets.append(pos + offset)
	
	return unit_targets

func is_mouse_over_ui() -> bool:
	return get_viewport().gui_get_hovered_control() != null

func start_drag():
	dragging = true
	selection_box.visible = true
	selection_box.global_position = camera.get_viewport_transform() * drag_start
	selection_box.size = Vector2.ZERO
	
func update_drag(current_pos: Vector2):
	var drag_start_screen = camera.get_viewport_transform() * drag_start
	var current_pos_screen = camera.get_viewport_transform() * current_pos
	var top_left = Vector2(
		min(drag_start_screen.x, current_pos_screen.x),
		min(drag_start_screen.y, current_pos_screen.y)
	)
	var size = (current_pos_screen - drag_start_screen).abs()
	
	selection_box.global_position = top_left
	selection_box.size = size
	
func end_drag(shift):
	dragging = false
	selection_box.visible = false
	
	select_units_in_box(Rect2(selection_box.global_position, selection_box.size), shift)
			
func select_units_in_box(box: Rect2, shift) -> void:
	if !shift:
		for unit in selected_units:
			unit.set_selected(false)
		selected_units.clear()
		player_ui.clear_control_group()
		
	for unit in selectable_units:
		if unit.owner_id != player_id: continue
		var screen_pos = camera.get_viewport_transform() * unit.global_position
		### if hits unit
		if box.has_point(screen_pos):
			### if hits and not already selected
			if unit not in selected_units:
				player_ui.add_unit_to_control(unit)
				selected_units.append(unit)
				unit.set_selected(true)	

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
		if collider and collider.has_method("set_selected"):
			return collider
		return false
		
func select_unit_at_mouse_pos(mouse_pos: Vector2, shift):
	var result = check_click_hit(mouse_pos)
	if result:
		if !shift:
			for unit in selected_units:
				unit.set_selected(false)
			selected_units.clear()
			player_ui.clear_control_group()
	
		result.set_selected(true)
		selected_units.append(result)
		player_ui.add_unit_to_control(result)

func _on_unit_died(unit):
	if unit in selectable_units:
		selectable_units.erase(unit)
		player_ui.remove_unit_from_group(unit)
