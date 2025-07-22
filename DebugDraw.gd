extends Node2D

var lines = []

func _draw():
	for line in lines:
		draw_line(line.start, line.end, line.color, 2.0)

func add_line(start: Vector2, end: Vector2, color: Color = Color.BLUE):
	lines.append({ "start": start, "end": end, "color": color })
	queue_redraw()
