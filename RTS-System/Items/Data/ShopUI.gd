extends Control

class_name ShopUI
var tab_container: TabContainer

var item_button_scene = preload("res://RTS-System/Items/Data/ShopItemButton.tscn")

var parent

func _ready() -> void:
	#load items
	tab_container = $Background/MarginContainer/ShopList
	for item in ItemDatabase.items.values():
		_add_item_to_shop(item)

func _add_item_to_shop(item: ItemData):
	if !tab_container.has_node(item.category):
		push_warning("No tab found: ", item.category)
		return
	
	var grid = tab_container.get_node(item.category + "/ScrollContainer/GridContainer")

	var item_button = item_button_scene.instantiate()
	item_button.get_node("Icon").texture = item.icon
	item_button.get_node("Cost").text = str(item.cost)
	grid.add_child(item_button)

	item_button.pressed.connect(func():
		_on_item_pressed(item))

	item_button.connect("mouse_entered", Callable(self, "_on_item_hover_entered").bind(item, item_button))
	item_button.connect("mouse_exited", Callable(self, "_on_item_hover_exited"))

func _on_item_pressed(item: ItemData):
	print("pressed")
	var selected_unit = parent.selected_unit
	if selected_unit != null:
		if selected_unit is Hero:
			selected_unit.unit_inventory.add_item(item)

func gather_item_info(item) -> String:
	var text = str(item.name, " ", item.cost, "\n\n", item.description, "\n\n")

	for stat in item.stats.get_stats_dictionary().keys():
		var value = item.stats.get_stats_dictionary()[stat]
		text += str(stat, ": ", value, "\n")
	
	return text

func _on_item_hover_entered(item, item_button):
	var text = gather_item_info(item)

	TooltipManager.show_tooltip(parent.player_object.player_id, text, tab_container.global_position)

func _on_item_hover_exited():
	TooltipManager.hide_tooltip(parent.player_object.player_id)
