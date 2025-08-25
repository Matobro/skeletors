extends Control

class_name UnitInventoryUI

@onready var slot_scene = preload("res://RTS-System/Items/Data/InventorySlot.tscn")
var inventory: UnitInventory

var inventory_slots: GridContainer

func _ready() -> void:
	inventory_slots = $SlotsContainer

func set_inventory(new_inventory: UnitInventory) -> void:
	if inventory:
		inventory.disconnect("inventory_changed", Callable(self, "_update_slots"))

	inventory = new_inventory

	if inventory:
		inventory.connect("inventory_changed", Callable(self, "_update_slots"))

	_create_slots()
	_update_slots()

func _create_slots():
	for child in inventory_slots:
		child.queue_free()
	
	if !inventory:
		return

	for i in range(inventory.max_slots):
		var slot = slot_scene.instantiate()
		inventory_slots.add_child(slot)

func _update_slots():
	if !inventory: 
		return
		
	var slots = inventory_slots.get_children()
	for i in range (slots.size()):
		if i < inventory.items.size():
			slots[i].set_item(inventory.items[i])
		else:
			slots[i].set_item(null)
