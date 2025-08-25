extends Node

class_name PlayerInputHandler

var parent: PlayerInput
var command_issuer: PlayerCommandIssuer
var selection_manager: SelectionManager
var player_ui

func _init(parent_ref, command_issuer_ref, selection_manager_ref, player_ui_ref):
	parent = parent_ref
	command_issuer = command_issuer_ref
	selection_manager = selection_manager_ref
	player_ui = player_ui_ref

func input_received(event, event_info):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				parent.drag_start = event_info.pos
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

func on_left_click_pressed(event_info):
	### Attack move if holding A
	parent.drag_start = event_info.pos

	if event_info.total_units > 0 and event_info.attack_moving:
		if event_info.click_target:
			command_issuer.issue_attack_command(event_info)
		else:
			command_issuer.issue_attack_move_command(event_info)
		return
	
	### If not A moving: select clicked target
	if event_info.click_target and !event_info.attack_moving:
		if selection_manager.last_clicked_unit == event_info.click_target:
			selection_manager.select_all_units_of_type(event_info.click_target)
			selection_manager.last_clicked_unit = null
			return
		selection_manager.last_clicked_unit = event_info.click_target

func on_left_click_released(event_info):
	if event_info.attack_moving:
		return

	# If dragging then end drag and return
	if parent.dragging:
		parent.end_drag(event_info.is_queued)
		return
	
	# If not dragging then select at clicked position
	else:
		selection_manager.select_unit_at_mouse_pos(event_info.pos, event_info.is_queued)

	if event_info.click_target:
		selection_manager.last_clicked_unit = event_info.click_target

func on_right_click_pressed(event_info):
	if event_info.click_target and event_info.click_target.owner_id == 10:
		command_issuer.issue_attack_command(event_info)
	else:
		command_issuer.issue_move_command(event_info)

func on_right_click_released(_event_info):
	pass

func on_mouse_drag(event_info):
	### IF not started yet, then start dragging
	if !parent.dragging:
		if event_info.pos.distance_to(parent.drag_start) > parent.DRAG_THRESHOLD:
			parent.start_drag()

	### Update if draggin
	if parent.dragging and !event_info.attack_moving:
		parent.update_drag(event_info.pos)

func on_mouse_drag_end(event_info):
	if parent.dragging:
		parent.end_drag(event_info.is_queued)
	pass
