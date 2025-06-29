extends CharacterBody2D

class_name Unit

@onready var dev_state = $DevState

###UNIT DATA###
@onready var color_tag = $Polygon2D
@onready var state_machine = $UnitStateMachine
@onready var animation_player = $AnimatedSprite2D
var owner_id: int
var data : UnitData
var commands: CommandsData

###MOVEMENT###
var selected: bool
var movement_target = null
var command_queue := [] #stores commands, "type" "position" eg, "attack_move" "Vector2(0, 0)"
var rally_points: = [] #holds visuals of rally points from queued commands

###COMBAT###
var attack_move_target = null
var attack_target = null
var possible_targets = [] #all enemies inside aggro range
var is_attack_moving: bool = false
var dead: bool
var has_attacked: bool
var is_attack_committed: bool
var attack_anim_timer := 0.0
var attack_timer := 0.0

### UNIT INITIALIZATION ###
func init_unit(unit_data):
	await get_tree().process_frame
	
	animation_player.init_animations(unit_data.unit_model_data)
	data = unit_data.duplicate()
	dead = false
	set_selected(false)
	
	await get_tree().process_frame
	
	init_stats()
	
func init_stats():
	data.stats.current_health = data.stats.max_health
	data.stats.attack_damage = data.stats.base_damage
### UNIT INITIALIZATION END ###

### HEALTH LOGIC ###
func take_damage(damage):
	if dead: return
	
	data.stats.current_health -= damage
	clamp(data.stats.current_health, 0, data.stats.max_health)
	
	if data.stats.current_health <= 0:
		set_selected(false)
		dead = true
	
### HEALTH LOGIC END ###

### COMBAT LOGIC ###
func _physics_process(delta):
	if attack_timer >= 0:
		attack_timer -= delta
		
func perform_attack():
	if attack_target != null:
		attack_target.take_damage(data.stats.attack_damage)
		
### COMBAT LOGIC END ###
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
func issue_command(command_type: String, pos: Vector2, queue: bool, player_id: int) -> void:
	if owner_id != player_id: return

	if queue:
		command_queue.append({"type": command_type, "position": pos})
	else:
		is_attack_committed = false
		command_queue.clear()
		movement_target = null
		attack_move_target = null
		is_attack_moving = false
		attack_target = null
		for rally_point in rally_points:
			if is_instance_valid(rally_point): 
				rally_point.queue_free()
			else: continue
		rally_points.clear()
		
		command_queue.append({"type": command_type, "position": pos})
		
		if command_type == "move":
			movement_target = pos
			state_machine.set_state(state_machine.states.moving)
		elif command_type == "attack_move":
			attack_move_target = pos
			is_attack_moving = true
			state_machine.set_state(state_machine.states.attack_moving)
	add_rally_point(command_type, pos, queue)
			
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
func move_to_target(tar):
	#if tar == null: return
	var direction = (tar - position)
	velocity = direction.normalized() * data.stats.movement_speed
	move_and_slide()
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
		if closest_enemy_in_aggro_range().position.distance_to(position) < data.stats.range:
			return closest_enemy_in_aggro_range()
	
	return null
		
func _on_aggro_range_body_entered(body: Node2D):
	if body.is_in_group("unit"):
		if body.owner_id != self.owner_id:
			possible_targets.append(body)
			
func _on_aggro_range_body_exited(body: Node2D):
	if possible_targets.has(body):
		possible_targets.erase(body)
### AGGRO LOGIC END ###
