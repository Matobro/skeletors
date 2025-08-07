extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var radius: float

func _ready():
	update_scale()
	
func set_radius(r: float):
	radius = r
	update_scale()

func update_scale():
	if sprite.texture:
		var tex_size = sprite.texture.get_width() / 2.0
		var scale_factor = radius / tex_size
		sprite.scale = Vector2.ONE * scale_factor
