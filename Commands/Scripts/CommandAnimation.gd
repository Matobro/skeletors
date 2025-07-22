extends Node2D
@onready var sprite_anim: AnimatedSprite2D = $AnimatedSprite2D

func init_node(sprite_frames: SpriteFrames, is_timed: bool):
	if sprite_frames == null:
		push_warning("Empty command visual")
		return
	sprite_anim.sprite_frames = sprite_frames
	sprite_anim.play("default")
	if is_timed:
		await sprite_anim.animation_finished
		queue_free()
