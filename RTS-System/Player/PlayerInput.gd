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

var command_cooldown_frames := 0
var block_input_frames: int = 0
var selected_units: Array[Unit] = []

var fullscreen: bool = true
var last_clicked_unit = null

const DOUBLE_CLICK_TIME = 0.3
const DRAG_THRESHOLD := 50.0
const COMMAND_COOLDOWN := 10

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

	if command_cooldown_frames > 0:
		command_cooldown_frames -= 1

	if !is_input_enabled:
		selection_box.visible = false
		return
	
	cleanup_invalid_units()

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
	if event.is_action_pressed("8"):
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2(1920, 1080))
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen = !fullscreen
	elif event.is_action_pressed("s"):
		issue_stop_command(get_key_event_info())
	elif event.is_action_pressed("h"):
		issue_hold_command(get_key_event_info())
	elif selected_units.size() > 0:
		match event.keycode:
			KEY_Q:
				selected_units[0].cast_ability(0, get_global_mouse_position(), get_tree().current_scene)
			KEY_W:
				selected_units[0].cast_ability(1, get_global_mouse_position(), get_tree().current_scene)
			KEY_E:
				selected_units[0].cast_ability(2, get_global_mouse_position(), get_tree().current_scene)
				
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
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag_start = event_info.pos
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
		if event_info.click_target:
			issue_attack_command(event_info)
		else:
			issue_attack_move_command(event_info)
		return

	### If not A moving: select clicked target
	elif event_info.click_target and !event_info.attack_moving:
		select_unit_at_mouse_pos(event_info.pos, event_info.is_queued)
		if last_clicked_unit == event_info.click_target:
			select_all_units_of_type(event_info.click_target)
			last_clicked_unit = null
			return
		last_clicked_unit = event_info.click_target
	

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
	if event_info.click_target and event_info.click_target.owner_id == 10:
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
		unit.command_holder.issue_command("Stop", event_info.click_target, event_info.pos, event_info.is_queued, player_id)

func issue_hold_command(event_info):
	for unit in selected_units:
		unit.command_holder.issue_command("Hold", event_info.click_target, event_info.pos, event_info.is_queued, player_id)
	
func issue_attack_command(event_info):
	for unit in selected_units:
		unit.command_holder.issue_command("Attack", event_info.click_target, event_info.pos, event_info.is_queued, player_id)
	
func issue_attack_move_command(event_info):
	var formation = calculate_unit_formation(event_info.total_units, event_info.pos)
	for i in range (selected_units.size()):
		var unit = selected_units[i]
		var target_pos = formation[i]
		unit.command_holder.issue_command(
			"Attack_move",
			event_info.click_target,
			target_pos,
			event_info.is_queued,
			player_id
		)

	command_cooldown_frames = COMMAND_COOLDOWN
func issue_move_command(event_info):
	#print("Clicked pos:", event_info.pos)
	var formation = calculate_unit_formation(event_info.total_units, event_info.pos)
	for i in range (selected_units.size()):
		var unit = selected_units[i]
		var target_pos = formation[i]
		unit.command_holder.issue_command(
			"Move",
			event_info.click_target,
			target_pos,
			event_info.is_queued,
			player_id
		)

	command_cooldown_frames = COMMAND_COOLDOWN

func select_all_units_of_type(unit):
	print("called select all")
	for selected_unit in selected_units:
		print("Unselecting")
		selected_unit.set_selected(false)
	selected_units.clear()
	player_ui.clear_control_group()

	var _owner = unit.owner_id
	var unit_type = unit.data.name

	for other_unit in UnitHandler.all_units:
		if other_unit.owner_id == _owner and other_unit.data.name == unit_type:
			other_unit.set_selected(true)
			selected_units.append(other_unit)
			player_ui.add_unit_to_control(other_unit)
			
func center_of_mass(units: Array) -> Vector2:
	var center := Vector2.ZERO
	for u in units:
		center += u.global_position
	return center / units.size()

func calculate_unit_formation(total_units, pos):
	if total_units == 1:
		return [pos]
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
	
	select_units_in_box(Rect2(selection_box.global_position, selection_box.size), shift)

func world_to_screen(world_pos: Vector2) -> Vector2:
	var cam_pos = camera.global_position
	var zoom = camera.zoom
	var screen_center = camera.get_viewport_rect().size / 2
	return screen_center + (world_pos - cam_pos) * zoom

func select_units_in_box(box: Rect2, shift: bool) -> void:
	var units_in_box: Array = []
	var own_units_in_box: Array = []
	var enemy_units_in_box: Array = []

	# Add units to array in the selection
	for unit in UnitHandler.all_units:
		var screen_pos = world_to_screen(unit.global_position)
		if box.has_point(screen_pos):
			units_in_box.append(unit)
			if unit.owner_id == player_id:
				own_units_in_box.append(unit)
			else:
				enemy_units_in_box.append(unit)

	# Decice what to select
	var new_selection: Array = []
	if own_units_in_box.size() > 0:
		new_selection = own_units_in_box
	elif enemy_units_in_box.size() > 0:
		new_selection = enemy_units_in_box

	# Get current selection owner
	var current_owner_id: int = -1
	if selected_units.size() > 0:
		current_owner_id = selected_units[0].owner_id

	# If not holding shift, clear previous selection
	if !shift:
		for unit in selected_units:
			unit.set_selected(false)
		selected_units.clear()
		player_ui.clear_control_group()
	else:
		# If holding shift, filter selection to allow only units of same player
		if current_owner_id != -1:
			new_selection = new_selection.filter(func(u): return u.owner_id == current_owner_id)

	# Add filtered units
	for unit in new_selection:
		if unit not in selected_units:
			unit.set_selected(true)
			selected_units.append(unit)
			player_ui.add_unit_to_control(unit)

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
	return null


func select_unit_at_mouse_pos(mouse_pos: Vector2, shift: bool):
	var clicked_unit = check_click_hit(mouse_pos)
	if clicked_unit == null:
		return
	
	var clicked_owner = clicked_unit.owner_id

	if not shift:
		# Clear all selection
		for unit in selected_units:
			unit.set_selected(false)
		selected_units.clear()
		player_ui.clear_control_group()

		# Select the clicked unit
		clicked_unit.set_selected(true)
		selected_units.append(clicked_unit)
		player_ui.add_unit_to_control(clicked_unit)
	else:
		# Shift is held
		if selected_units.size() == 0:
			# No current selection, allow any
			clicked_unit.set_selected(true)
			selected_units.append(clicked_unit)
			player_ui.add_unit_to_control(clicked_unit)
		else:
			var current_owner = selected_units[0].owner_id
			if clicked_owner == current_owner:
				if clicked_unit in selected_units:
					# Deselect if already selected
					clicked_unit.set_selected(false)
					selected_units.erase(clicked_unit)
					player_ui.remove_unit_from_control(clicked_unit)
				else:
					# Add to selection
					clicked_unit.set_selected(true)
					selected_units.append(clicked_unit)
					player_ui.add_unit_to_control(clicked_unit)
			else:
				# Different owner, ignore
				pass
