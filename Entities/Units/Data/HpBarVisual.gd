extends Control

@onready var hp_bar = $".."

var max_hp: int
var line_color: Color = Color.BLACK
var line_width: float = 2.0

func init_hp_bar(hp, _max_hp):
	max_hp = _max_hp
	hp_bar.max_value = max_hp
	set_hp_bar(hp)
	queue_redraw()
	
func set_hp_bar(hp):
	hp_bar.value = hp
	
func set_bar_visible(value):
	hp_bar.visible = value

func set_bar_position(sprite_size, scaling, pos):
	var scaled_height = sprite_size * scaling
	var top_of_sprite = pos - scaled_height

	var bar_offset = 50.0
	hp_bar.position.y = top_of_sprite + bar_offset

func _draw() -> void:
	if max_hp <= 1:
		return
	
	var width = size.x
	var height = size.y
	for i in range(1, 10):
		var x = (i / float(10)) * width
		draw_line(Vector2(x, 0), Vector2(x, height), line_color, line_width)
