extends Resource

class_name UnitModelData

@export var sprite_frames: SpriteFrames
@export var offset: Vector2
@export var scale: Vector2 = Vector2.ONE
@export var extra_mass: float = 0.0
@export var animation_attack_point: float = 0.5
@export var animation_attack_duration: float = 1.0

func get_unit_radius_world_space() -> float:
	var tex = sprite_frames.get_frame_texture("idle", 0)
	if tex:
		var world_width = tex.get_width() * scale.x
		var world_height = tex.get_height() * scale.y
		return max(world_width, world_height) / 4.0
	return 32.0  # fallback radius
