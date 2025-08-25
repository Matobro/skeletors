extends Node

class_name UnitInventory

@export var max_slots: int = 6

var items: Array = []

signal item_added(item: ItemData)
signal item_removed(item: ItemData)
signal inventory_changed()

func add_item(item: ItemData) -> bool:
    if items.size() >= max_slots:
        return false
    items.append(item)
    emit_signal("item_added", item)
    emit_signal("inventory_changed")
    return true

func remove_item(item: ItemData) -> bool:
    if item in items:
        items.erase(item)
        emit_signal("item_removed", item)
        emit_signal("inventory_changed")
        return true
    return false

func drop_item(item: ItemData, world_position: Vector2) -> bool:
    if remove_item(item):
        #spawn item
        return true
    return false

func give_item(item: ItemData, target_inventory: UnitInventory) -> bool:
    if remove_item(item):
        return target_inventory.add_item(item)
    return false

func get_item_bonus(stat_name: String) -> float:
    var total = 0.0
    for item in items:
        if item.stats and item.stats.get_stats_dictionary().has(stat_name):
            total += item.stats.get_stats_dictionary()[stat_name]
    return total
