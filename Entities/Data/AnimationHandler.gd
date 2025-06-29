extends AnimatedSprite2D

func init_animations(data):
	sprite_frames = data.sprite_frames
	scale = data.scale
	play("idle")
