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
		if !is_valid_unit(unit):
			if unit == parent.selected_unit:
				for u in selected_units:
					if is_valid_unit(u):
						parent.selected_unit = u
						break
			continue

		var slot_instance = unit_slot.instantiate()
		current_control_group.add_child(slot_instance)
		slot_instance.init_unit(unit)
		slot_instance.connect("pressed", Callable(self, "_on_unit_slot_pressed").bind(unit))
	
	current_control_group.visible = true

func is_valid_unit(unit) -> bool:
	if is_instance_valid(unit) and unit != null and unit.unit_combat and !unit.unit_combat.dead:
		return true
	return false

func _on_unit_slot_pressed(unit: Unit):
	if parent == null or parent.player_object == null:
		return
	
	var selection_manager = parent.player_object.player_input.selection_manager
	selection_manager.apply_selection([unit], false)
