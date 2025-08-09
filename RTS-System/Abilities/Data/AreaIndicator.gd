extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var radius: float
var lifetime: float

var lifetime_timer: Timer

func _ready():
	update_scale()
	lifetime_timer = Timer.new()
	if lifetime <= 0:
		queue_free()
		return

	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	add_child(lifetime_timer)
	lifetime_timer.timeout.connect(_on_timer_timeout)
	lifetime_timer.start()
	
func set_radius(r: float):
	radius = r
	update_scale()

func update_scale():
	if sprite.texture:
		var tex_size = sprite.texture.get_width() / 2.0
		var scale_factor = radius / tex_size
		sprite.scale = Vector2.ONE * scale_factor

func _on_timer_timeout():
	queue_free()