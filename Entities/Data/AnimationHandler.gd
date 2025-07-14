extends AnimatedSprite2D

func init_animations(data):
	if !data or !data.sprite_frames:
		print("No sprite_frames found in UnitModelData")
		
	sprite_frames = data.sprite_frames
	scale = data.scale
	play("idle")
