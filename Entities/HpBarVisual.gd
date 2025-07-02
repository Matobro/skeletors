extends Control

@onready var hp_bar = $".."
@onready var hp_bar_label = $"../../HpBarLabel"

var max_hp: int
var line_color: Color = Color.BLACK
var line_width: float = 2.0

func init_hp_bar(hp, _max_hp):
	max_hp = _max_hp
	hp_bar_label.text = str(hp)
	hp_bar.max_value = max_hp
	queue_redraw()
	
func set_hp_bar(hp):
	hp_bar.value = hp
	hp_bar_label.text = str(hp)
	
func set_bar_visible(value):
	hp_bar.visible = value
	
func _draw() -> void:
	if max_hp <= 1:
		return
	
	var width = size.x
	var height = size.y
	for i in range(1, 10):
		var x = (i / float(10)) * width
		draw_line(Vector2(x, 0), Vector2(x, height), line_color, line_width)
