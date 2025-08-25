extends Control
class_name UnitInventoryUI

@onready var slot_scene = preload("res://RTS-System/Items/Data/InventorySlot.tscn")
var inventory: UnitInventory

var inventory_slots: GridContainer
var slots: Array = []

func _ready() -> void:
	inventory_slots = $SlotsContainer

func set_inventory(new_inventory: UnitInventory) -> void:
	# Disconnect previous inventory signals
	if inventory and inventory.is_connected("inventory_changed", Callable(self, "_update_slots")):
		inventory.disconnect("inventory_changed", Callable(self, "_update_slots"))

	inventory = new_inventory

	# Connect to the new inventory
	if inventory:
		inventory.connect("inventory_changed", Callable(self, "_update_slots"))

	# Ensure we have the correct number of slots
	_create_slots()
	_update_slots()

func _create_slots():
	if not inventory:
		return

	# Adjust the number of slot nodes to match max_slots
	while slots.size() < inventory.max_slots:
		var slot = slot_scene.instantiate()
		inventory_slots.add_child(slot)
		slots.append(slot)

	while slots.size() > inventory.max_slots:
		var slot = slots.pop_back()
		slot.queue_free()

func _update_slots():
	if not inventory:
		for slot in slots:
			slot.set_item(null)
		return

	for i in range(slots.size()):
		if i < inventory.items.size():
			slots[i].set_item(inventory.items[i])
		else:
			slots[i].set_item(null)
