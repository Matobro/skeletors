extends Node

class_name UnitVisual

var selected: bool = true
var facing_right: bool = true

var unit_scale: float = 16

var parent: Unit
var animation_player: AnimatedSprite2D
var hp_bar

func _init(parent_ref, animation_player_ref, hp_bar_ref) -> void:
	parent = parent_ref
	animation_player = animation_player_ref
	hp_bar = hp_bar_ref

	unit_scale = parent.data.unit_model_data.get_unit_radius_world_space() /2

	set_selected(false)
	set_unit_color(parent_ref.owner_id)
	
	hp_bar.init_hp_bar(parent.data.stats.current_health, parent.data.stats.max_health)

func set_selected(value: bool):
	if value == selected:
		return
	
	selected = value
	parent.modulate = Color(1, 1, 1) if selected else Color(0.5, 0.5, 0.5)

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