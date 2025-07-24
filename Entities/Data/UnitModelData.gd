extends Resource

class_name UnitModelData

@export var sprite_frames: SpriteFrames
@export var offset: Vector2
@export var scale: Vector2 = Vector2.ONE
@export var extra_mass: float = 0.0
@export var animation_attack_point: float = 0.5
@export var animation_attack_duration: float = 1.0

func get_unit_scale_from_sprite() -> float:
	var tex = sprite_frames.get_frame_texture("idle", 0)
	if tex:
		var size: float = tex.get_size().x
		return size * (scale.x * 0.25)
	
	push_warning("Couldn't get sprite, defaulting to 16")
	return 16
