extends Node2D

class_name ChainLightningBeam

@onready var line: Line2D = $Line2D

@export var lifetime := 0.1
@export var width := 6.0
@export var color := Color(0.6, 0.9, 1.0)
@export var segments := 16
@export var jaggedness := 32.0

var age := 0.0

func setup(start_pos: Vector2, end_pos: Vector2):
	position = Vector2.ZERO
	line.clear_points()
	line.width = width
	line.default_color = color
	line.points = _generate_points(start_pos, end_pos)

func _process(delta: float) -> void:
	age += delta
	if age > lifetime:
		queue_free()
	else:
		line.width = width * (1.0 + randf_range(-0.15, 0.15))
		line.default_color = color.lightened(randf_range(-0.1, 0.1))

func _generate_points(start_pos: Vector2, end_pos: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var pos = start_pos.lerp(end_pos, t)
		if i > 0 and i < segments:
			pos += Vector2(randf_range(-jaggedness, jaggedness), randf_range(-jaggedness, jaggedness))
		points.append(pos)
	return points
