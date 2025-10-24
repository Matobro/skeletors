extends Node

class_name UnitVisual

var selection_circle_front: Node2D
var selection_circle_back: Node2D
var buff_front: Node2D
var buff_back: Node2D

var selected: bool = true
var facing_right: bool = true
var targeting: bool = false
var target

var unit_scale: float = 16

var parent: Unit
var animation_player: AnimatedSprite2D
var hp_bar: Control
var target_marker

func _init(parent_ref, animation_player_ref, hp_bar_ref, target_marker_ref, circle_front_ref, circle_back_ref, buff_front_ref, buff_back_ref):
	parent = parent_ref
	hp_bar = hp_bar_ref
	target_marker = target_marker_ref
	selection_circle_front = circle_front_ref
	selection_circle_back = circle_back_ref
	buff_front = buff_front_ref
	buff_back = buff_back_ref
	animation_player = animation_player_ref

	unit_scale = parent.data.unit_model_data.get_unit_radius_world_space() /2

func initialize_visuals():
	var scale = parent.data.unit_model_data.scale
	selection_circle_front.scale = scale
	selection_circle_back.scale = scale

	var unit_height = animation_player.get_frame_size().y * parent.data.unit_model_data.scale.y
	selection_circle_front.position.y = animation_player.position.y + (unit_height / 2) + parent.data.unit_model_data.offset.y
	selection_circle_back.position.y = selection_circle_front.position.y

	set_unit_color(parent.owner_id)
	hp_bar.init_hp_bar(parent.data.stats.current_health, parent.data.stats.max_health)

	set_selected(false)

func _process(_delta: float):
	if target:
		target_marker.global_position = target.global_position + Vector2(0, -75)

func set_selected(value: bool):
	if value == selected:
		return
	
	selected = value
	targeting = value
	if selected == true and target != null:
		target_marker.visible = true
	else:
		target_marker.visible = false

	var selected_color = Color(1, 1, 1, 1)
	var circle_unselected_color = Color(0.5, 0.5, 0.5)
	selection_circle_back.modulate = selected_color if selected else circle_unselected_color
	selection_circle_front.modulate = selected_color if selected else circle_unselected_color

func set_target(new_target):
	target = new_target
	if targeting and target != null:
		target_marker.visible = true

func clear_target():
	target = null
	target_marker.visible = false

func handle_orientation(direction: Vector2):
	if direction.x == 0:
		return  # ignore if going straight up/down

	if abs(direction.x) < 0.4:
		return  # ignore small movements

	if direction.x > 0 and !facing_right:
		animation_player.flip_h = false
		facing_right = true
	elif direction.x < 0 and facing_right:
		animation_player.flip_h = true
		facing_right = false

func set_unit_color(owner_id):
	var sprite_material = animation_player.material
	if sprite_material and sprite_material is ShaderMaterial:
		sprite_material.set_shader_parameter("outline_color", PlayerManager.get_player_color(owner_id))

## Attaches visual effect [fx] to string [pos]
func attach_fx(fx, pos, value):
	var fx_instance = AnimatedSprite2D.new()
	fx_instance.sprite_frames = fx

	#no judging
	if value == 0:
		buff_front.add_child(fx_instance)
		fx_instance.material = parent.buff_layer_front.material
	else:
		buff_back.add_child(fx_instance)
		fx_instance.material = parent.buff_layer_back.material
	
	fx_instance.scale = animation_player.scale
	fx_instance.position = animation_player.get_pos(parent, pos)
	return fx_instance

func remove_fx(fx):
	for effect in fx:
		effect.queue_free()
