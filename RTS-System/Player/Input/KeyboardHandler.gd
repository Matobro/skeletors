extends RefCounted

class_name KeyboardHandler

var is_fullscreen: bool

var player_input: PlayerInput
var command_issuer: PlayerCommandIssuer
var selection_manager: SelectionManager
var input_handler: PlayerInputHandler

func _init(player_input_ref, command_issuer_ref, selection_manager_ref, input_handler_ref) -> void:
	player_input = player_input_ref
	command_issuer = command_issuer_ref
	selection_manager = selection_manager_ref
	input_handler = input_handler_ref

func handle_keyboard_commands(event: InputEventKey):
	var event_info = create_event_info(event)

	if event.is_action_pressed("8"):
		toggle_fullscreen()
	elif event.is_action_pressed("s"):
		command_issuer.issue_stop_command(event_info)
	elif event.is_action_pressed("h"):
		command_issuer.issue_hold_command(event_info)
	elif event.is_action_pressed("i"):
		player_input.player_ui.shop_ui.visible = !player_input.player_ui.shop_ui.visible
		pass
	elif selection_manager.selected_units.size() > 0:
		match event.keycode:
			KEY_Q:
				cast_spell(0, event_info.clicked_position, event_info.click_target, event_info.shift)

func cast_spell(index, clicked_position, clicked_target, shift):
	if selection_manager.is_valid_selection():
		command_issuer.issue_cast_ability_command(
		selection_manager.selected_units[0], 
		index, 
		clicked_position, 
		clicked_target, 
		shift
		)

func toggle_fullscreen():
	is_fullscreen = !is_fullscreen

	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2(1920, 1080))
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func create_event_info(event) -> EventInfo:
	var info := EventInfo.new()
	info.clicked_position = player_input.get_global_mouse_position()
	info.click_target = player_input.check_click_hit(info.clicked_position)
	info.click_item = player_input.check_click_hit_item(info.clicked_position)
	info.total_units = selection_manager.selected_units.size()
	info.shift = event.is_action_pressed("shift")
	info.attack_moving = event.is_action_pressed("a")
	return info
