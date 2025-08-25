extends Node

class_name PlayerUI

var selected_unit: Unit

var player_object
var ui_stats: UIUnitStats
var ui_tooltips: UIStatTooltips
var ui_control_group: UIControlGroup

func init_node(parent_ref):
	player_object = parent_ref
	player_object.player_input.selection_manager.selection_changed.connect(on_selection_changed)

func _ready() -> void:
	ui_stats = UIUnitStats.new()
	ui_control_group = UIControlGroup.new()
	ui_tooltips = UIStatTooltips.new(self, ui_stats)

	add_child(ui_stats)
	add_child(ui_control_group)
	add_child(ui_tooltips)
	
	hide_ui()

func on_selection_changed(selected_units):
	hide_ui()
	if selected_units.size() <= 0:
		selected_unit = null
		return
	
	selected_unit = selected_units[0]

	# If only one unit selected
	if selected_units.size() == 1:
		show_stats(selected_unit)

	# If multiple units selected
	else:
		ui_control_group.show_control_group(selected_units)
		show_bars(selected_unit)

func show_group():
	pass

func show_stats(unit: Unit):
	ui_stats.show_unit_stats(unit)

func show_bars(unit: Unit):
	ui_stats.show_ui_bars(unit)

func hide_ui():
	ui_control_group.hide_control_group()
	ui_stats.hide_unit_stats()
	ui_stats.hide_ui_bars()
