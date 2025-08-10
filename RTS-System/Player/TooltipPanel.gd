extends Panel

@onready var label = $Label

func show_tooltip(text: String, _position: Vector2):
	label.text = text

	size = label.get_minimum_size() + Vector2(50, 50)
	global_position = Vector2(_position.x, _position.y - (size.y + 5))

	visible = true

func hide_tooltip():
	label.text = ""
	size = Vector2.ZERO
	visible = false
