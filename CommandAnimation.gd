extends Node2D
@onready var sprite_anim: AnimatedSprite2D = $AnimatedSprite2D

func init_node(sprite, isTimed):
	if sprite is int: return
	sprite_anim.sprite_frames = sprite
	sprite_anim.play("default")
	if isTimed:
		await sprite_anim.animation_finished
		queue_free()
