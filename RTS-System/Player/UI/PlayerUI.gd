extends Node
class_name PlayerUI

var ui_inventory: UnitInventoryUI
var action_panel
var action_text
var shop_scene = preload("res://RTS-System/Items/Data/ShopUI.tscn")
var selected_unit: Unit
var selected_units: Array

var player_object
var ui_stats: UIUnitStats
var ui_tooltips: UIStatTooltips
var ui_control_group: UIControlGroup
var shop_ui: ShopUI
var action_menu: ActionMenuUI

var node_ready: bool = false

func init_node(parent_ref):
	ui_inventory = $Inventory
	action_panel = $ActionPanel
	action_text = $ActionPanel/ActionText

	player_object = parent_ref
	player_object.player_input.selection_manager.selection_changed.connect(on_selection_changed)

	ui_stats = UIUnitStats.new()
	ui_control_group = UIControlGroup.new(self)
	ui_tooltips = UIStatTooltips.new(self, ui_stats)
	shop_ui = shop_scene.instantiate()
	shop_ui.parent = self
	action_menu = ActionMenuUI.new(self)

	add_child(ui_stats)
	add_child(ui_control_group)
	add_child(ui_tooltips)
	add_child(shop_ui)
	add_child(action_menu)

	ui_inventory.parent = self

	node_ready = true
	hide_ui()

func _process(_delta):
	if node_ready:
		if selected_units.size() > 1 and selected_unit:
			ui_stats.show_ui_bars(selected_unit)
			ui_stats.hide_unit_stats()
			ui_control_group.show_control_group(selected_units)
		elif selected_units.size() == 1 and selected_unit:
			ui_stats.show_unit_stats(selected_unit)
			ui_control_group.hide_control_group()
		else:
			hide_ui()

func on_selection_changed(new_selection: Array) -> void:
	selected_units = new_selection
	var new_selected_unit: Unit = new_selection[0] if new_selection.size() > 0 else null

	if new_selected_unit != null:
		action_menu.update_action_menu(new_selected_unit.unit_ability_manager.abilities)
	
	if new_selected_unit == null:
		action_menu.update_action_menu()

	# Update ui if it actually changed
	if selected_unit != new_selected_unit:
		selected_unit = new_selected_unit
		if selected_unit != null:
			if selected_unit is Hero:
				ui_inventory.set_inventory(selected_unit.unit_inventory)

		elif selected_unit == null or selected_unit is not Hero:
			ui_inventory.set_inventory(null)

func hide_ui():
	ui_control_group.hide_control_group()
	ui_stats.hide_unit_stats()
	ui_stats.hide_ui_bars()

func display_action_panel(text):
	action_text.text = text
	action_panel.visible = true

func hide_action_panel():
	action_panel.visible = false
