extends Node

class_name UnitInventory

var dropped_item_scene = preload("res://RTS-System/Items/Data/DroppedItem.tscn")
@export var max_slots: int = 6

var items: Array = []

var parent

signal item_added(item: ItemData)
signal item_removed(item: ItemData)
signal inventory_changed()

func _init(parent_ref) -> void:
	parent = parent_ref

	items.resize(max_slots)
	for i in range(max_slots):
		items[i] = null

func add_item(item: ItemData) -> bool:
	for i in range(max_slots):
		if items[i] == null:
			items[i] = item
			emit_signal("item_added", item)
			emit_signal("inventory_changed")
			parent.data.stats.recalculate_stats()
			return true
	return false

func remove_item(item: ItemData) -> bool:
	for i in range(max_slots):
		if items[i] == item:
			items[i] = null
			emit_signal("item_removed", item)
			emit_signal("inventory_changed")
			parent.data.stats.recalculate_stats()
			return true
	return false

func drop_item(slot_index: int, world_position: Vector2) -> bool:
	var item = items[slot_index]
	if item == null:
		return false

	items[slot_index] = null
	emit_signal("item_removed", item)
	emit_signal("inventory_changed")
	parent.data.stats.recalculate_stats()

	# Spawn dropped item
	var dropped_item = dropped_item_scene.instantiate()
	dropped_item.global_position = world_position
	dropped_item.set_item(item)
	get_tree().current_scene.add_child(dropped_item)
	return true

func give_item(item: ItemData, target_inventory: UnitInventory) -> bool:
	if remove_item(item):
		return target_inventory.add_item(item)
	return false

func move_item(from_index: int, to_index: int):
	if from_index == to_index:
		return
	
	if to_index < 0 or to_index >= max_slots or from_index < 0 or from_index >= max_slots:
		return

	var temp = items[to_index]
	items[to_index] = items[from_index]
	items[from_index] = temp

	emit_signal("inventory_changed")
	
## Returns false if no space, true is there is space
func is_space_in_inventory():
	for i in range(max_slots):
		if items[i] == null:
			return true
	return false

func get_item_bonus(stat_name: String) -> float:
	var total = 0.0
	for item in items:
		if item != null and item.stats and item.stats.get_stats_dictionary().has(stat_name):
			total += item.stats.get_stats_dictionary()[stat_name]
	return total
