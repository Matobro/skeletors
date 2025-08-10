extends Resource

class_name UnitModelData

## Should be unique for each different unit
## Animations (NAMED EXACTLY) [attack] [dying] [idle] [walk]
@export var sprite_frames: SpriteFrames
## Default for somereason is 2, so use that as a base
@export var scale: Vector2 = Vector2.ONE

## At which point (in seconds) of the animation damage is dealt
@export var animation_attack_point: float = 0.5
## Should be attack animation length, scaling done elsewhere
@export var animation_attack_duration: float = 1.0

## Projectile scene for ranged attacks - not needed if melee
@export var projectile_scene = preload("res://RTS-System/Entities/Projectiles/HomingProjectile.tscn")
## Projectile speed
@export var projectile_speed = 300

func get_unit_radius_world_space() -> float:
	var tex = sprite_frames.get_frame_texture("idle", 0)
	if tex:
		var world_width = tex.get_width() * scale.x
		var world_height = tex.get_height() * scale.y
		return max(world_width, world_height) / 4.0
	return 32.0  # fallback radius
