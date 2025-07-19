extends CharacterBody2D

class_name Unit

@onready var dev_state = $DevState

###############
var damage_text: DamageTextPool
###UNIT DATA###
@onready var state_machine = $UnitStateMachine
@onready var animation_player = $AnimatedSprite2D
@onready var animation_library = $AnimationPlayer
@onready var aggro_collision = $AggroRange/CollisionShape2D
@onready var hp_bar = $HpBar/Control
var owner_id: int
var data : UnitData
var commands: CommandsData
var facing_right: bool = true

###DEV###
var dev_counter := 0
var frame_skip: int = 0

##NAVIGATION##
@onready var pathfinding_agent : NavigationAgent2D = $Pathfinding
var pathfinding_timer = 10
var pathfinding_speed = 10

###MOVEMENT###
var max_push_checks: int = 2
var push_mass: float = 1.0
var push_vectors = {}
var push_velocity: Vector2 = Vector2.ZERO
var push_min_distance: float = 16
var smoothed_direction := Vector2.ZERO
var selected: bool
var following: bool
var movement_target = null
var follow_target = null
var command_queue := [] #stores commands, "type" "position" eg, "attack_move" "Vector2(0, 0)"
var rally_points: = [] #holds visuals of rally points from queued commands
var holding_position: bool = false

###COMBAT###
var abilities: Array[Ability]
var attack_move_target = null
var attack_target = null
var possible_targets = [] #all enemies inside aggro range
var friendly_targets = []
var is_attack_moving: bool = false
var dead: bool
var has_attacked: bool
var is_attack_committed: bool
var attack_anim_timer := 0.0
var attack_timer := 0.0
var attackers := []

signal died(unit)

### UNIT INITIALIZATION ###
func _ready():
	pathfinding_timer = randi() % pathfinding_speed + 1
	
	
func init_unit(unit_data):
	await get_tree().process_frame

	animation_library.add_animation_library("animations", unit_data.unit_library)
	animation_player.init_animations(unit_data.unit_model_data)
	state_machine.animation_player = animation_player
	state_machine.animation_library = animation_library
	data = unit_data.duplicate()
	dead = false
	set_selected(false)
	aggro_collision.set_deferred("disabled", false)
	set_unit_color()
	push_min_distance = 8 * (data.unit_model_data.scale.y)
	push_mass = (data.unit_model_data.scale.y) * data.unit_model_data.extra_mass
	await get_tree().process_frame
	
	state_machine.set_ready()
	init_stats()
	
func init_stats():
	data.stats = data.stats.duplicate()

	#lol
	data.stats.max_health = data.stats.base_max_hp
	data.stats.max_mana = data.stats.base_max_mana
	data.stats.armor = data.stats.base_armor
	data.stats.movement_speed = data.stats.base_movement_speed
	data.stats.health_regen = data.stats.base_health_regen
	data.stats.mana_regen = data.stats.base_mana_regen
	data.stats.attack_speed = data.stats.base_attack_speed
	data.stats.attack_range = data.stats.base_range
	data.stats.current_health = data.stats.max_health
	data.stats.current_mana = data.stats.max_mana
	data.stats.attack_damage = data.stats.base_damage

	###reduces lag (maybe)
	if data.unit_type == "unit":
		var rng = randi_range(-10, 10)
		data.stats.attack_range += rng
		

	hp_bar.init_hp_bar(data.stats.current_health, data.stats.max_health)
	# check_if_valid_stats()
	
func set_unit_color():
	var sprite_material = animation_player.material
	if sprite_material and sprite_material is ShaderMaterial:
		match owner_id:
			1: sprite_material.set_shader_parameter("outline_color", Color.GREEN)
			2: sprite_material.set_shader_parameter("outline_color", Color.BLUE)
			3: sprite_material.set_shader_parameter("outline_color", Color.SANDY_BROWN)
			4: sprite_material.set_shader_parameter("outline_color", Color.TEAL)
			5: sprite_material.set_shader_parameter("outline_color", Color.YELLOW)
			6: sprite_material.set_shader_parameter("outline_color", Color.ORANGE)
			7: sprite_material.set_shader_parameter("outline_color", Color.PURPLE)
			8: sprite_material.set_shader_parameter("outline_color", Color.HOT_PINK)
			9: sprite_material.set_shader_parameter("outline_color", Color.GRAY)
			10: sprite_material.set_shader_parameter("outline_color", Color.RED)

### UNIT INITIALIZATION END ###

### HEALTH LOGIC ###
func take_damage(damage):
	if dead: return

	data.stats.current_health -= damage
	clamp(data.stats.current_health, 0, data.stats.max_health)
	hp_bar.set_hp_bar(data.stats.current_health)
	damage_text.show_text(str(damage), animation_player.global_position)
	if data.stats.current_health <= 0:
		set_selected(false)
		hp_bar.set_bar_visible(false)
		dead = true
		emit_signal("died", self)
	
### HEALTH LOGIC END ###

func _physics_process(delta):
	if frame_skip > 0:
		push_vectors.clear()
		frame_skip = 0
		if friendly_targets.size() > 0 or possible_targets.size() > 0:
			for unit in friendly_targets:
				if unit.dead:
					friendly_targets.erase(unit)
					continue
				if !holding_position:
					unit.get_body_push(friendly_targets)
		
			for unit in possible_targets:
				if unit.dead:
					possible_targets.erase(unit)
					continue
				if !holding_position:
					unit.get_body_push(possible_targets)

			for unit in friendly_targets:
				if unit.dead:
					friendly_targets.erase(unit)
					continue
				if !holding_position:
					unit.apply_body_push(delta)

			for unit in possible_targets:
				if unit.dead:
					possible_targets.erase(unit)
					continue
				if !holding_position:
					unit.apply_body_push(delta)

	if attack_timer > 0:
		attack_timer -= delta

	frame_skip += 1

		
### COMBAT LOGIC ###

func get_attack_delay() -> float:
	return 1.0 / data.stats.attack_speed

func cast_ability(index: int, pos: Vector2, world_node: Node):
	if index < 0 or index >= abilities.size():
		return

	var ability = abilities[index]
	var ability_instance = ability.activate_ability(pos, world_node, self)

	if ability_instance != null:
		world_node.add_child(ability_instance)

	
func register_attacker(unit: Node2D):
	if !attackers.has(unit):
		attackers.append(unit)
		
func unregister_attacker(unit: Node2D):
	attackers.erase(unit)

func get_attack_index(unit: Node2D) -> int:
	return attackers.find(unit)
	
func perform_attack():
	if attack_target != null:
		var dice = data.stats.attack_dice_roll
		var dmg = data.stats.attack_damage
		var dice_roll = randi_range(-dice, dice)
		var result = dmg + dice_roll
		var damage = clampi(result, 1, 9999)
		attack_target.take_damage(damage)

func on_attack_start():
	if attack_target:
		attack_target.register_attacker(self)

func on_attack_stop():
	if attack_target:
		attack_target.unregister_attacker(self)
	is_attack_committed = false
	has_attacked = false
	attack_anim_timer = 0.0
	
func set_selected(value: bool):
	selected = value
	if selected:
		modulate = Color (1,1,1)
		for rally_point in rally_points:
			if is_instance_valid(rally_point):
				rally_point.visible = true
	else:
		for rally_point in rally_points:
			if is_instance_valid(rally_point):
				rally_point.visible = false
		modulate = Color (0.5,0.5,0.5)

### COMMAND LOGIC ###
func issue_command(command_type: String, pos: Vector2, queue: bool, player_id: int, target) -> void:
	if owner_id != player_id or command_type == null: return
	
	if queue:
		command_queue.append({"type": command_type, "position": pos})
	else:
		clear_unit_state()
		command_queue.clear()
		for rally_point in rally_points:
			if is_instance_valid(rally_point): 
				rally_point.queue_free()
			else: continue
		rally_points.clear()
		
		command_queue.append({"type": command_type, "position": pos})
		
		if command_type == "move":
			movement_target = pos
			pathfinding_agent.target_position = pos
			state_machine.set_state(state_machine.states.moving)
		elif command_type == "attack_move":
			attack_move_target = pos
			pathfinding_agent.target_position = pos
			is_attack_moving = true
			state_machine.set_state(state_machine.states.attack_moving)
		elif command_type == "attack":
			attack_target = target
			state_machine.set_state(state_machine.states.aggroing)
		elif command_type == "follow":
			follow_target = target
			state_machine.set_state(state_machine.states.following)
		elif command_type == "stop":
			state_machine.set_state(state_machine.states.idle)
		elif command_type == "hold":
			state_machine.set_state(state_machine.states.hold)
	
	add_rally_point(command_type, pos, queue)

func clear_unit_state():
		is_attack_committed = false
		movement_target = null
		attack_move_target = null
		is_attack_moving = false
		attack_target = null
		following = false
		follow_target = null
		
func add_rally_point(command_type: String, pos, queue):
	var command = null
	var timed = false
	match command_type:
		"move":  
			if queue: 
				command = commands.rally_point
			else:
				command = commands.move_command
				timed = true
		"attack_move":
			if queue:
				command = commands.attack_move_rally
			else:
				command = commands.attack_move_command
				timed = true
		"attack":
			command = commands.attack_move_command
			timed = true
		"follow":
			command = commands.move_command
			timed = true
		"stop":
			command = commands.empty_command
		"hold":
			command = commands.empty_command
			
	create_command_visual(pos, command, timed, queue)
	
func create_command_visual(pos, command, timed, queue):
	var command_inst = commands.command_object.instantiate()
	command_inst.global_position = pos
	get_tree().current_scene.add_child(command_inst)
	command_inst.init_node(command, timed)
	
	command_inst.set_meta("queue", queue)
	rally_points.append(command_inst)
	
func clear_rally_point(): # used in state machine
	if rally_points.size() > 0:
		var rally = rally_points.pop_front()
		if is_instance_valid(rally):
			rally.queue_free()
		
func get_current_command():
	if command_queue.size() > 0:
		return command_queue[0]
	return null
		
### COMMAND LOGIC END ###

### MOVEMENT LOGIC ###
func move_to_target():
	pathfinding_timer += 1

	var to_target = Vector2.ZERO
	if pathfinding_agent.target_position != Vector2.ZERO:
		var next_path_point = pathfinding_agent.get_next_path_position()
		to_target = (next_path_point - global_position).normalized()
	
	var adjusted_direction = get_avoidance_adjustment(to_target, friendly_targets)

	if adjusted_direction.length() > 0.01:
		smoothed_direction = smoothed_direction.lerp(adjusted_direction, 0.2)
	else:
		smoothed_direction = smoothed_direction.lerp(Vector2.ZERO, 0.1)

	if smoothed_direction.length() < 0.01:
		smoothed_direction = Vector2.ZERO

	handle_orientation(smoothed_direction)

	var raw_velocity = smoothed_direction * data.stats.movement_speed

	if smoothed_direction.dot(to_target) < 0.3:
		velocity = (raw_velocity + push_velocity) / 4
	else:
		velocity = raw_velocity + push_velocity

	move_and_slide()

	if pathfinding_timer > pathfinding_speed + 1:
		pathfinding_timer = 0
		
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
				
func get_body_push(other_units: Array):
	var push_checks := 0
	for other in other_units:
		if other == self:
			continue

		if push_checks >= max_push_checks:
			break

		push_checks += 1
		var to_other = global_position - other.global_position
		var distance = to_other.length()

		var combined_push_distance = max(push_min_distance, other.push_min_distance)

		if distance < combined_push_distance and distance > 0:
			var push_strength = (combined_push_distance - distance) * 100.0

			var push_dir = to_other.normalized()
			var push_self = push_dir * (push_strength / push_mass)
			var push_other = -push_dir * (push_strength / other.push_mass)

			push_velocity += push_self

			if !other.holding_position:
				other.push_velocity += push_other

func get_avoidance_adjustment(target_direction: Vector2, blocking_units: Array) -> Vector2:
	var avoidance_force := Vector2.ZERO
	var min_separation := 32.0
	
	for other in blocking_units:
		if other == self:
			continue
		
		if other.holding_position:
			var to_other = global_position - other.global_position
			var distance = to_other.length()
			if distance < min_separation and distance > 0:
				var strength = ((min_separation - distance) / min_separation) * 2.0
				avoidance_force += to_other.normalized() * strength
	
	if avoidance_force.length() > 0.01:
		var avoidance_weight = clamp(avoidance_force.length(), 1.0, 5.9)
		return (target_direction.normalized() * (1.0 - avoidance_weight) + avoidance_force.normalized() * avoidance_weight).normalized()
	else:
		return target_direction.normalized()
	
func apply_body_push(delta):
	if push_velocity.length() > 0.01:
		push_velocity = push_velocity.lerp(Vector2.ZERO, 1.0 * delta)
		var max_push_speed = 150.0
		if push_velocity.length() > max_push_speed:
			push_velocity = push_velocity.normalized() * max_push_speed

	else:
		push_velocity = Vector2.ZERO


### MOVEMENT LOGIC END ###

### AGGRO LOGIC ###
func compare_distance(target_a, target_b):
	return position.distance_to(target_a.position) < position.distance_to(target_b.position)

func closest_enemy_in_aggro_range() -> Unit: #closest enemy target in aggro range
	for unit in possible_targets:
		if unit.dead:
			if attack_target == unit:
				attack_target = null
				possible_targets.erase(unit)
	if possible_targets.size() > 0:
		possible_targets.sort_custom(Callable(self, "compare_distance"))
		return possible_targets[0]
	else:
		return null

func closest_enemy_in_attack_range() -> Unit: #closest enemy in attack range
	if closest_enemy_in_aggro_range() != null:
		if closest_enemy_in_aggro_range().position.distance_to(position) < data.stats.attack_range:
			return closest_enemy_in_aggro_range()
	
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
