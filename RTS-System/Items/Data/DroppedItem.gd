extends Area2D

class_name DroppedItem

@onready var sprite = $Sprite2D
var item: ItemData

func set_item(new_item: ItemData):
	sprite = $Sprite2D
	item = new_item
	if item.icon:
		sprite.texture = item.icon

func _ready() -> void:
	connect("mouse_entered", Callable(self, "_on_mouse_enter"))
	connect("mouse_exited", Callable(self, "_on_mouse_exit"))
	connect("input_event", Callable(self, "_on_input_event"))

func _on_mouse_enter():
	if item:
		var text = get_item_text(item)
		TooltipManager.show_tooltip(1, text, get_viewport().get_mouse_position())
		print("showing tooltip")

func _on_mouse_exit():
	print("hiding tooltip")
	TooltipManager.hide_tooltip(1)

func _on_input_event(viewport, event, shape_idx):
	pass

func get_item_text(item) -> String:
	var text = str(item.name, " ", item.cost, "\n\n", item.description, "\n\n")

	for stat in item.stats.get_stats_dictionary().keys():
		var value = item.stats.get_stats_dictionary()[stat]
		text += str(stat, ": ", value, "\n")
	
	return text
	
