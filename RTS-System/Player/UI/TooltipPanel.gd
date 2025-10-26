extends Panel

@onready var label = $Label

func show_tooltip(text: String, _position: Vector2):
	label.bbcode_text = text

	var new_size = Vector2(label.get_content_width(), label.get_content_height())
	size = new_size + Vector2(75, 50)

	global_position = Vector2(_position.x, _position.y - (size.y + 5))
	visible = true

func hide_tooltip():
	label.text = ""
	size = Vector2.ZERO
	visible = false
