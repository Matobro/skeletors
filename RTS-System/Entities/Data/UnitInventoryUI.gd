extends Control
class_name UnitInventoryUI

@onready var slot_scene = preload("res://RTS-System/Items/Data/InventorySlot.tscn")
var inventory: UnitInventory

var inventory_slots: GridContainer
var slots: Array = []

var parent

func _ready() -> void:
	inventory_slots = $SlotsContainer
	_create_slots()

func set_inventory(new_inventory: UnitInventory) -> void:
	if inventory and inventory.is_connected("inventory_changed", Callable(self, "_update_slots")):
		inventory.disconnect("inventory_changed", Callable(self, "_update_slots"))

	inventory = new_inventory

	if inventory:
		inventory.connect("inventory_changed", Callable(self, "_update_slots"))

	_update_slots()

func _create_slots():
	for i in range(6):
		var slot = slot_scene.instantiate()
		inventory_slots.add_child(slot)
		slots.append(slot)

		slot.connect("mouse_entered", Callable(self, "_on_inventory_hover_enter").bind(i))
		slot.connect("mouse_exited", Callable(self, "_on_inventory_hover_exit"))
		slot.connect("gui_input", Callable(self, "_on_inventory_slot_input").bind(i))

func _update_slots():
	if !inventory:
		for slot in slots:
			slot.set_item(null)
		return

	for i in range(slots.size()):
		slots[i].set_item(inventory.items[i])

func get_item_text(item) -> String:
	var text = str(item.name, " ", item.cost, "\n\n", item.description, "\n\n")

	for stat in item.stats.get_stats_dictionary().keys():
		var value = item.stats.get_stats_dictionary()[stat]
		text += str(stat, ": ", value, "\n")
	
	return text

func _on_inventory_slot_input(event: InputEvent, slot_index):
	if !inventory or !inventory.items:
		return

	if event is InputEventMouseButton and event.pressed:
		var slot_item = inventory.items[slot_index]
		var player_input = parent.player_object.player_input
		# Right click = drop mode
		if event.button_index == MOUSE_BUTTON_RIGHT and slot_item != null:
			if player_input:
				player_input.item_handler.set_drop_mode(slot_item, slot_index, true)
		# Left click while in drop/move mode
		elif event.button_index == MOUSE_BUTTON_LEFT and player_input.item_handler.drop_mode:
			if slot_index >= 0:
				# Swap/move items
				inventory.move_item(player_input.item_handler.item_slot_index, slot_index)
				player_input.item_handler.set_drop_mode(null, false)
				TooltipManager.hide_tooltip(parent.player_object.player_id)
				_on_inventory_hover_enter(slot_index)

func _on_inventory_hover_enter(slot_index):
	if !inventory or !inventory.items:
		return

	var slot_item = inventory.items[slot_index]
	if slot_item != null:
		var text = get_item_text(slot_item)
		TooltipManager.show_tooltip(parent.player_object.player_id, text, inventory_slots.global_position)


func _on_inventory_hover_exit():
	TooltipManager.hide_tooltip(parent.player_object.player_id)
