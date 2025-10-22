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
	var event_info := create_event_info(event)
	var selected_unit = selection_manager.get_first_selected_unit()

	if event.is_action_pressed("8"):
		toggle_fullscreen()
	elif event.is_action_pressed("s"):
		command_issuer.issue_stop_command(event_info)
	elif event.is_action_pressed("h"):
		command_issuer.issue_hold_command(event_info)
	elif event.is_action_pressed("i"):
		player_input.player_ui.shop_ui.visible = !player_input.player_ui.shop_ui.visible
		pass
	# If unit selected
	elif selected_unit and selected_unit.owner_id == player_input.player_id:
		match event.keycode:
			# Pass event_info, caster, index of ability (Q = index 0, W = index 1)
			KEY_Q:
				player_input.is_casting = false
				input_cast_spell(event_info, selected_unit, 0)
			KEY_W:
				player_input.is_casting = false
				input_cast_spell(event_info, selected_unit, 1)

## Saves cast if not quick cast, casts spell if is quick cast or cast is saved
func input_cast_spell(event_info: EventInfo = null, caster: Unit = null, index: int = -1):
	if !selection_manager.is_valid_selection():
		print("Invalid selection")
		player_input.is_casting = false
		return
	
	if !index < caster.unit_ability_manager.abilities.size():
		print("Unit has no ability for this slot")
		player_input.is_casting = false
		return

	#EventInfo
	#Create context for the casted ability
	if !player_input.is_casting:
		var context = CastContext.new()
		context.caster = caster 
		context.index = index 
		context.target_position = event_info.clicked_position 
		context.target_unit = event_info.click_target
		context.shift = event_info.shift 
		context.ability = caster.unit_ability_manager.abilities[index]

		#Check for cooldown and mana and for valid cast if quick cast
		if !context.ability.can_cast(context) or (player_input.is_quick_cast and !context.ability.is_valid_cast(context)):
			print("Cant cast")
			player_input.player_ui.hide_action_panel()
			player_input.is_casting = false
			return
			
		# Quick cast if enabled
		if player_input.is_quick_cast or context.ability.ability_data.is_instant_cast:
			player_input.player_ui.hide_action_panel()
			player_input.is_casting = false
			cast_spell(context)
			return
		# Toggle casting mode if all good
		else:
			print("Toggling cast spell")
			toggle_cast_spell(context)
	# If in casting mode
	else:
		player_input.player_ui.hide_action_panel()
		player_input.is_casting = false
		cast_spell(player_input.desired_cast)

func toggle_cast_spell(context):
	player_input.player_ui.display_action_panel(context.ability.ability_data.get_info_text())
	player_input.is_casting = true
	player_input.desired_cast = context

## Sends command request with [CastContext] to [PlayerCommandIssuer]
func cast_spell(context: CastContext):
	print("casting spell")
	if !context.ability.is_valid_cast(context):
		print("Invalid cast")
		return

	command_issuer.issue_cast_ability_command(context)
	player_input.player_ui.hide_action_panel()
	player_input.is_casting = false

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
