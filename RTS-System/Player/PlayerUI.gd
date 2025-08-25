extends Node
class_name PlayerUI

@onready var ui_inventory: UnitInventoryUI = $Inventory

var shop_scene = preload("res://RTS-System/Items/Data/ShopUI.tscn")
var selected_unit: Unit

var player_object
var ui_stats: UIUnitStats
var ui_tooltips: UIStatTooltips
var ui_control_group: UIControlGroup
var shop_ui: ShopUI

func init_node(parent_ref):
	player_object = parent_ref
	player_object.player_input.selection_manager.selection_changed.connect(on_selection_changed)

func _ready() -> void:
	ui_stats = UIUnitStats.new()
	ui_control_group = UIControlGroup.new(self)
	ui_tooltips = UIStatTooltips.new(self, ui_stats)
	shop_ui = shop_scene.instantiate()
	shop_ui.parent = self

	add_child(ui_stats)
	add_child(ui_control_group)
	add_child(ui_tooltips)
	add_child(shop_ui)

	hide_ui()

func on_selection_changed(selected_units: Array) -> void:
	# Determine the new "main" unit
	var new_selected_unit: Unit = selected_units[0] if selected_units.size() > 0 else null

	# Update inventory only if it actually changed
	if selected_unit != new_selected_unit:
		selected_unit = new_selected_unit
		if selected_unit != null and selected_unit is Hero:
			ui_inventory.set_inventory(selected_unit.unit_inventory)
		else:
			ui_inventory.set_inventory(null)

	# Handle UI visibility
	hide_ui()
	if selected_unit:
		if selected_units.size() == 1:
			show_stats(selected_unit)
		else:
			ui_control_group.show_control_group(selected_units)
			show_bars(selected_unit)

func show_stats(unit: Unit):
	ui_stats.show_unit_stats(unit)

func show_bars(unit: Unit):
	ui_stats.show_ui_bars(unit)

func hide_ui():
	ui_control_group.hide_control_group()
	ui_stats.hide_unit_stats()
	ui_stats.hide_ui_bars()
