extends AnimatedSprite2D

func init_animations(data, unit):
	if !data or !data.sprite_frames:
		print("No sprite_frames found in UnitModelData")

	sprite_frames = data.sprite_frames
	scale = data.scale
	unit.collider.global_position = unit.global_position
	play("idle")

func get_frame_size():
	var _sprite = sprite_frames.get_frame_texture(
		animation,
		frame
	)
	return _sprite.get_size()

func get_animation_speed(anim: String) -> float:
	var base_frames = sprite_frames.get_frame_count(anim)
	var base_fps = sprite_frames.get_animation_speed(anim)
	return float(base_frames) / float(base_fps)

## Plays [animation] with [animation_speed]. 0.1 = 0.1x speed, 2.0 = 2x speed
func play_animation(animation_name: String = "idle", animation_speed: float = 1.0):
	set_speed_scale(animation_speed)
	play(animation_name)

## Returns position of sprite (center, top, bottom)
func get_pos(unit, pos: String = "center") -> Vector2:
	var frame_height = get_frame_size().y * unit.data.unit_model_data.scale.y

	var base_pos = Vector2(position.x, position.y + unit.data.unit_model_data.offset.y)
	var half_height = frame_height / 2.5

	match pos:
		"center":
			return base_pos
		"top":
			return Vector2(base_pos.x, base_pos.y - half_height)
		"bottom":
			return Vector2(base_pos.x, base_pos.y + half_height)
		_:
			return base_pos
