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
var dead: bool = false
var facing_right: bool = true
var selected: bool = true
var unit_scale: float = 16

var attack_timer: float = 0.0
var attack_anim_timer: float = 0.0
var has_attacked: bool = false
var is_attack_committed: bool = false
var is_holding_position: bool = false
var is_ranged: bool
var is_moving: bool = false
var is_ready: bool = false
var is_invunerable: bool = true
### Combat

var attack_target: Unit = null
var possible_targets: Array = []
var friendly_targets: Array = []

var command_holder: CommandHolder
var unit_ai: UnitAI

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
	
	create_unit_ai()
	is_invunerable = false
	#hp_bar.set_bar_position(animation_player.get_frame_size().y, animation_player.scale.y, animation_player.position.y)

func create_unit_ai():
	command_holder = CommandHolder.new(self)
	unit_ai = UnitAI.new(self, command_holder)
	unit_ai.init_ai()
	add_child(unit_ai)

func connect_signals():
	SpatialGrid.register_unit(self)
	is_ready = true

func _on_command_completed(_command_type: String):
	pass

func set_unit_color():
	var sprite_material = animation_player.material
	if sprite_material and sprite_material is ShaderMaterial:
		sprite_material.set_shader_parameter("outline_color", PlayerManager.get_player_color(owner_id))

func _physics_process(delta: float):
	if attack_timer > 0:
		attack_timer -= delta

func get_distance_to(_target):
	return global_position.distance_to(_target)

func is_within_attack_range(_target) -> bool:
	return data.stats.attack_range + 2 > get_distance_to(_target) # add slight range boost so units dont get stuck

func get_stat(stat: String):
	return data.stats[stat]

func regenate_health():
	if data.stats.health_regen <= 0:
		return
	
	data.stats.current_health = min(data.stats.current_health + data.stats.health_regen, data.stats.max_health)
	hp_bar.set_hp_bar(data.stats.current_health)

func take_damage(damage: int, attacker = null):
	if dead or is_invunerable: return

	var reduction = 1.0 - StatModifiers.calculate_armor(data.stats.armor)
	var final_damage = damage * reduction
	damage = clamp(final_damage, 1, 9999)
	data.stats.current_health -= damage
	data.stats.current_health = clamp(data.stats.current_health, 0, data.stats.max_health)
	hp_bar.set_hp_bar(data.stats.current_health)

	DamageText.show_text(str(damage), animation_player.global_position)
	
	if data.stats.current_health <= 0:
		set_selected(false)
		hp_bar.set_bar_visible(false)
		dead = true
		emit_signal("died", self)
		unit_ai.set_state("Dying")
		return

	# if attacker and unit_ai.current_state == unit_ai.states["Idle"] and attacker.owner_id != owner_id:
	# 	command_holder.issue_command(
	# 		"Attack",
	# 		attacker,
	# 		attacker.global_position,
	# 		false,
	# 		owner_id
	# 	)

func get_attack_delay() -> float:
	var attack_speed = data.stats.attack_speed
	if attack_speed <= 0:
		attack_speed = 0.01
	return 1.0 / attack_speed

func cast_ability(index: int, pos: Vector2, world_node: Node):
	if index < 0 or index >= abilities.size():
		return

	var ability = abilities[index]
	var ability_instance = ability.activate_ability(pos, world_node, self)

	if ability_instance != null:
		world_node.add_child(ability_instance)

func perform_attack():
	if attack_target != null:
		var dice = data.stats.attack_dice_roll
		var dmg = data.stats.attack_damage
		var dice_roll = randi_range(-dice, dice)
		var result = dmg + dice_roll
		var damage = clampi(result, 1, 9999)
		attack_target.take_damage(damage, self)

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
				
func compare_distance(target_a, target_b):
	return position.distance_to(target_a.position) < position.distance_to(target_b.position)

func closest_enemy_in_aggro_range() -> Unit:
	if possible_targets.size() <= 0:
		return null
		
	var closest_unit: Unit = null
	var closest_distance := INF

	for unit in possible_targets:
		if unit.dead:
			if attack_target == unit:
				attack_target = null
			possible_targets.erase(unit)
		else:
			var dist := position.distance_to(unit.position)
			if dist < closest_distance:
				closest_distance = dist
				closest_unit = unit

	return closest_unit

func closest_enemy_in_attack_range() -> Unit:
	var closest_unit = closest_enemy_in_aggro_range()
	if closest_unit and position.distance_to(closest_unit.position) < data.stats.attack_range:
		return closest_unit
	return null
		
func _on_aggro_range_body_entered(body: Node2D):
	if body.is_in_group("unit"):
		if body.owner_id != self.owner_id:
			possible_targets.append(body)
		if body.owner_id == self.owner_id:
			friendly_targets.append(body)
			
func _on_aggro_range_body_exited(body: Node2D):
	if possible_targets.has(body):
		if body.owner_id != self.owner_id:
			possible_targets.erase(body)

		if body.owner_id == self.owner_id:
			friendly_targets.erase(body)
### AGGRO LOGIC END ###
