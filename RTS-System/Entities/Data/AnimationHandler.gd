extends AnimatedSprite2D

var selection_circle_front = null
var selection_circle_back = null

func init_animations(data, unit):
	if !data or !data.sprite_frames:
		print("No sprite_frames found in UnitModelData")

	selection_circle_front = $"../SelectionCircleFront"
	selection_circle_back = $"../SelectionCircleBack"
	sprite_frames = data.sprite_frames
	selection_circle_front.scale = data.scale
	selection_circle_back.scale = data.scale
	scale_upwards(self, data.scale)
	set_selection_circle_position(unit)
	play("idle")

func scale_upwards(sprite_to_scale, target_scale):
	sprite_to_scale.scale = target_scale

func get_frame_size():
	var _sprite = sprite_frames.get_frame_texture(
		animation,
		frame
	)
	return _sprite.get_size()

func set_selection_circle_position(unit):
	var unit_height = get_frame_size().y * scale.y
	selection_circle_front.position.y = position.y + (unit_height / 2) + unit.data.unit_model_data.offset.y
	selection_circle_back.position.y = selection_circle_front.position.y
	unit.collider.global_position = unit.global_position
