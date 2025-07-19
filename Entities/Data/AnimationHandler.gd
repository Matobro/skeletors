extends AnimatedSprite2D

var selection_circle_front = null
var selection_circle_back = null

func init_animations(data):
	if !data or !data.sprite_frames:
		print("No sprite_frames found in UnitModelData")

	selection_circle_front = $"../SelectionCircleFront"
	selection_circle_back = $"../SelectionCircleBack"
	sprite_frames = data.sprite_frames
	selection_circle_front.scale = data.scale
	selection_circle_back.scale = data.scale
	scale_upwards(self, data.scale)
	set_selection_circle_position()
	play("idle")

func scale_upwards(sprite_to_scale, target_scale):
	var height = get_frame_size(sprite_to_scale).y
	var difference = sprite_to_scale.scale.y - 1.0

	sprite_to_scale.scale = target_scale
	sprite_to_scale.position.y -= (height * difference) / 2

func get_frame_size(sprite_to_scale):
	var _sprite = sprite_to_scale.sprite_frames.get_frame_texture(
		sprite_to_scale.animation,
		sprite_to_scale.frame
	)
	return _sprite.get_size()

func set_selection_circle_position():
	var unit_height = get_frame_size(self).y * scale.y
	selection_circle_front.position.y = position.y + (unit_height / 3)
	selection_circle_back.position.y = selection_circle_front.position.y
