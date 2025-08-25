extends Node

class_name UIControlGroup

var unit_slot = preload("res://RTS-System/Entities/Data/UnitSlot.tscn")
@onready var current_control_group = $"../CurrentControlGrid"

var parent: PlayerUI

func _init(parent_ref) -> void:
	parent = parent_ref

func clear_control_group():
	for child in current_control_group.get_children():
		child.queue_free()

func hide_control_group():
	current_control_group.visible = false
	
func show_control_group(selected_units: Array):
	clear_control_group()
	for unit in selected_units:
		var slot_instance = unit_slot.instantiate()
		current_control_group.add_child(slot_instance)
		slot_instance.init_unit(unit)
		slot_instance.connect("pressed", Callable(self, "_on_unit_slot_pressed").bind(unit))
	
	current_control_group.visible = true

func _on_unit_slot_pressed(unit: Unit):
	if parent == null or parent.player_object == null:
		return
	
	var selection_manager = parent.player_object.player_input.selection_manager
	selection_manager.apply_selection([unit], false)
