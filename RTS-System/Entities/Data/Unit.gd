extends CharacterBody2D

class_name Unit

###UNIT DATA###
@onready var animation_player: AnimatedSprite2D = $AnimatedSprite2D
@onready var aggro_collision: CollisionShape2D = $AggroRange/CollisionShape2D
@onready var hp_bar: Control = $AnimatedSprite2D/HpBar/Control
@onready var collider = $CollisionShape2D

var owner_id: int
var data : UnitData
var abilities: Array[Ability]
var facing_right: bool = true
var selected: bool = true
var unit_scale: float = 16

var is_holding_position: bool = false
var is_ranged: bool
var is_moving: bool = false
var is_ready: bool = false

var command_holder: CommandHolder
var unit_ai: UnitAI
var unit_combat: UnitCombat

signal died(unit)

func init_unit():
	data = data.duplicate()
	await get_tree().process_frame

	_data_received()
	await get_tree().process_frame

	init_stats()
	assign_stuff()
	connect_signals()

func _data_received():
	pass

func init_stats():

	if data.stats is BaseStatData:
		data.stats = data.stats.duplicate()
		data.stats.recalculate_stats()

	hp_bar.init_hp_bar(data.stats.current_health, data.stats.max_health)
	
func assign_stuff():
	set_selected(false)
	set_unit_color()
	is_ranged = data.is_ranged
	aggro_collision.set_deferred("disabled", false)
	unit_scale = data.unit_model_data.get_unit_radius_world_space() /2

	data.avatar = data.unit_model_data.sprite_frames
	animation_player.init_animations(data.unit_model_data, self)

	data.parent = self
	if data.unit_type == "hero":
		var rof = load("res://RTS-System/Abilities/Resources/Rain of Fire.tres")
		abilities.append(rof)

		var shockwave = load("res://RTS-System/Abilities/Resources/Shockwave.tres")
		abilities.append(shockwave)
	
	create_unit()
	#hp_bar.set_bar_position(animation_player.get_frame_size().y, animation_player.scale.y, animation_player.position.y)

func create_unit():
	command_holder = CommandHolder.new(self)
	unit_ai = UnitAI.new(self, command_holder)
	unit_ai.init_ai()
	unit_combat = UnitCombat.new(self, data.stats)
	add_child(unit_ai)

func connect_signals():
	SpatialGrid.register_unit(self)
	is_ready = true

func set_unit_color():
	var sprite_material = animation_player.material
	if sprite_material and sprite_material is ShaderMaterial:
		sprite_material.set_shader_parameter("outline_color", PlayerManager.get_player_color(owner_id))

func get_stat(stat: String):
	return data.stats[stat]

func cast_ability(index: int, pos: Vector2, world_node: Node):
	if index < 0 or index >= abilities.size():
		return

	var ability = abilities[index]
	var ability_instance = ability.activate_ability(pos, world_node, self)

	if ability_instance != null:
		world_node.add_child(ability_instance)

func set_selected(value: bool):
	if value == selected:
		return
	
	selected = value
	modulate = Color(1, 1, 1) if selected else Color(0.5, 0.5, 0.5)

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
		
func _on_aggro_range_body_entered(body: Node2D):
	if body.is_in_group("unit"):
		if body.owner_id != self.owner_id:
			unit_combat.possible_targets.append(body)
		if body.owner_id == self.owner_id:
			unit_combat.friendly_targets.append(body)
			
func _on_aggro_range_body_exited(body: Node2D):
	if unit_combat.possible_targets.has(body):
		if body.owner_id != self.owner_id:
			unit_combat.possible_targets.erase(body)

		if body.owner_id == self.owner_id:
			unit_combat.friendly_targets.erase(body)
