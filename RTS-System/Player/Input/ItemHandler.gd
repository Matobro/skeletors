extends Node

class_name ItemHandler

var item_to_drop: ItemData
var item_slot_index: int
var drop_mode: bool = false

var player_ui: PlayerUI
var command_issuer: PlayerCommandIssuer

func _init(player_ui_ref, command_issuer_ref):
	player_ui = player_ui_ref
	command_issuer = command_issuer_ref

func handle_items(event_info) -> bool:
	if drop_mode and item_to_drop:
		if event_info.click_target and event_info.click_target is Hero:
			var inventory = event_info.click_target.unit_inventory
			if inventory.is_space_in_inventory():
				command_issuer.issue_give_item_command(event_info, item_to_drop)
		else:
			command_issuer.issue_drop_item_command(event_info, item_slot_index)
		
		set_drop_mode(null, false)
		return true
	return false

func set_drop_mode(item: ItemData = null, slot_index: int = -1, value = false):
	drop_mode = value
	
	if drop_mode:
		item_to_drop = item if item != null else null
		item_slot_index = slot_index
		player_ui.action_panel.visible = true
		player_ui.action_text.text = str("Left click to drop [", item.name, "]")
	else:
		item_to_drop = null
		player_ui.action_panel.visible = false
		player_ui.action_text.text = ""