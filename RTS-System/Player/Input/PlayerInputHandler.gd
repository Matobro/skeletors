extends Node

class_name PlayerInputHandler

var player_input: PlayerInput
var command_issuer: PlayerCommandIssuer
var selection_manager: SelectionManager
var player_ui: PlayerUI
var item_handler: ItemHandler

var multi_select_timer = 0.0

const MULTI_SELECT_TIME := 0.5

func _init(player_input_ref, command_issuer_ref, selection_manager_ref, player_ui_ref, item_handler_ref):
	player_input = player_input_ref
	command_issuer = command_issuer_ref
	selection_manager = selection_manager_ref
	player_ui = player_ui_ref
	item_handler = item_handler_ref

func input_received(event, event_info):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				player_input.drag_start = event_info.clicked_position
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
	player_input.drag_start = event_info.clicked_position

	if event_info.total_units > 0 and event_info.attack_moving:
		if event_info.click_target:
			command_issuer.issue_attack_command(event_info)
		else:
			command_issuer.issue_attack_move_command(event_info)
		return

func on_left_click_released(event_info):
	if event_info.attack_moving:
		return

	if player_input.dragging:
		player_input.end_drag(event_info.shift)
		return
	
	if item_handler.handle_items(event_info):
		return

	if event_info.click_target and !event_info.attack_moving:
		if selection_manager.last_clicked_unit == event_info.click_target and multi_select_timer > 0:
			selection_manager.select_all_units_of_type(event_info.click_target, event_info.shift)
			selection_manager.last_clicked_unit = null
			multi_select_timer = 0
			return
		
		selection_manager.last_clicked_unit = event_info.click_target
		multi_select_timer = MULTI_SELECT_TIME
	
	selection_manager.select_unit_at_mouse_pos(event_info.clicked_position, event_info.shift)

func on_right_click_pressed(event_info):
	if item_handler.drop_mode:
		item_handler.set_drop_mode(null, false)
		return

	if event_info.click_target and (event_info.click_target is Hero or event_info.click_target is Unit) and event_info.click_target.owner_id == 10:
		command_issuer.issue_attack_command(event_info)
	elif !event_info.click_target and event_info.click_item:
		command_issuer.issue_pickup_item_command(event_info)
	else:
		command_issuer.issue_move_command(event_info)
		
func on_right_click_released(_event_info):
	pass

func on_mouse_drag(event_info):
	### IF not started yet, then start dragging
	if !player_input.dragging:
		if event_info.clicked_position.distance_to(player_input.drag_start) > player_input.DRAG_THRESHOLD:
			player_input.start_drag()

	### Update if draggin
	if player_input.dragging and !event_info.attack_moving:
		player_input.update_drag(event_info.clicked_position)

func on_mouse_drag_end(event_info):
	if player_input.dragging:
		player_input.end_drag(event_info.shift)
	pass
