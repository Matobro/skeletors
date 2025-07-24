extends Node2D

var lines = []
var circles = []

var path: PackedVector2Array = []

func _draw():
	for line in lines:
		draw_line(line.start, line.end, line.color, 2.0)
	
	for circle in circles:
		draw_circle(circle.pos, circle.rad, circle.color, false, 2.0, false)

	if path.size() < 2:
		return

	for i in range(path.size() - 1):
		draw_line(path[i], path[i + 1], Color(1, 0, 0), 2)

	for point in path:
		draw_circle(point, 4, Color(0, 1, 0))

func add_line(start: Vector2, end: Vector2, color: Color = Color.BLUE):
	lines.append({ "start": start, "end": end, "color": color })
	queue_redraw()

func add_circle(pos, rad, color: Color = Color.BLUE):
	circles.append({ "pos": pos, "rad": rad, "color": color})
	queue_redraw()

func set_path(new_path: PackedVector2Array):
	path = new_path
	queue_redraw()

