extends Node

class_name UIControlGroup

var unit_slot = preload("res://RTS-System/Entities/Data/UnitSlot.tscn")
@onready var current_control_group = $"../CurrentControlGrid"

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
	
	current_control_group.visible = true
