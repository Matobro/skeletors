extends Label

var velocity := Vector2(0, -10)
var life_time := 1.0
var timer := 0.0

func _read():
	modulate.a = 1.0
	timer = 0.0

func _process(delta):
	position += velocity * delta
	timer += delta
	modulate.a = 1.0 - (timer / life_time)
	if timer >= life_time:
		hide()
