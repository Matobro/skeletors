extends StateMachine

### COMMENT SPAM WARNING, I CANT REMEMBER HOW STUFF WORKS ###
class_name UnitAI

signal command_completed(command_type)

var max_queue_size: int = 5

var current_command = null
var pathfinding_target: Vector2 = Vector2.ZERO
var aggro_check_timer: float = 0.0

var detour_target: Vector2 = Vector2.ZERO
var detour_timer: float = 0.0
const DETOUR_TIME: float = 1.0
const DETOUR_DISTANCE: float = 80.0
const BLOCKED_RADIUS: float = 48.0
const AGGRO_CHECK_INTERVAL: float = 1.0

func _ready():
	add_state("Idle")
	add_state("Move")
	add_state("Attack_move")
	add_state("Stop")
	add_state("Aggro")
	add_state("Attack")
	add_state("Dying")

func _on_command_issued(_command_type, _target, _position, is_queued):
	if state == "Idle" and current_command == null or !is_queued:
		_process_next_command()

func _process_next_command():
	### If no commands then return to idle
	var next_command = parent.command_component.get_next_command()

	if next_command == null:
		set_state("Idle")
		current_command = null
		return

	### Get next command, remove it from queue and signal current command to be done
	current_command = next_command
	parent.command_component.pop_next_command()

	emit_signal("command_completed", current_command.type)

	### Set correct state based on command
	match current_command.type:
		"Move":
			set_state("Move")
		"Attack":
			set_state("Aggro")
		"Attack_move":
			set_state("Attack_move")
		"Stop":
			set_state("Stop")
		_:
			set_state("Idle")

func enter_state(_new_state, _old_state):
	match _new_state:
		"Idle":
			animation_player.play("idle")
			parent.velocity = Vector2.ZERO
			aggro_check_timer = 0.0
		"Move":
			animation_player.play("walk")
		"Attack_move":
			aggro_check_timer = 0.0
			animation_player.play("walk")
		"Aggro":
			animation_player.play("walk")
		"Attack":
			parent.velocity  = Vector2.ZERO
		"Dying":
			parent.set_physics_process(false)
			parent.set_collision_layer(0)
			parent.set_collision_mask(0)
			animation_player.connect("animation_finished", Callable(self, "_on_death_animation_finished"), CONNECT_ONE_SHOT)
			animation_player.play("dying")
		"Stop":
			parent.velocity = Vector2.ZERO
			_process_next_command()

func exit_state(_old_state, _new_state):
	match _old_state:
		"Move":
			parent.velocity = Vector2.ZERO
			animation_player.stop()
		"Aggro":
			parent.velocity  = Vector2.ZERO
			animation_player.stop()
		"Attack":
			parent.velocity = Vector2.ZERO

func state_logic(delta):
	match state:
		"Idle":
			_idle_logic(delta)
		"Move":
			_move_logic(delta)
		"Attack_move":
			_attack_move_logic(delta)
		"Aggro":
			_aggro_logic(delta)
		"Attack":
			_attack_logic(delta)

func get_transition(_delta):
	return null

func _idle_logic(delta):
	if current_command != null:
		return

	parent.velocity = Vector2.ZERO
	aggro_check_timer += delta

	#Check enemies in aggro range every x seconds
	if aggro_check_timer > AGGRO_CHECK_INTERVAL:
		aggro_check_timer = 0.0

		#If enemy found issue attack command
		var enemy = parent.closest_enemy_in_aggro_range()
		if enemy != null:
			parent.command_component.issue_command("Attack", enemy, enemy.global_position, false, parent.owner_id) 

func _move_logic(delta):
	if current_command == null:
		set_state("Idle")
		return

	var nav_agent = parent.navigation_agent
	var target_position = current_command.target_position

	# --- DETOUR LOGIC ---
	if detour_target != Vector2.ZERO:
		# Move slower when detouring
		var slow_speed = parent.get_stat("movement_speed") * 0.75
		
		# Move towards detour target
		var detour_dir = (detour_target - parent.global_position).normalized()
		parent.velocity = detour_dir * slow_speed
		parent.move_and_slide()
		parent.handle_orientation(detour_dir)

		# Track how long we've been detouring
		detour_timer += delta

		# Consider detour finished if close enough OR detour time passed
		if parent.global_position.distance_to(detour_target) < 16 or detour_timer >= 1.0:
			detour_target = Vector2.ZERO
			detour_timer = 0.0
			
			# Recalculate path to original target after detouring
			nav_agent.target_position = target_position
			pathfinding_target = target_position

		# While detouring, skip the rest of the move logic
		return

	# --- NORMAL PATHFINDING & BLOCK CHECK ---
	
	# Recalculate path if target changed and not detouring
	if pathfinding_target != target_position:
		nav_agent.target_position = target_position
		pathfinding_target = target_position

	# Target reached
	if nav_agent.is_navigation_finished():
		_process_next_command()
		return

	# Check for blocking units
	var nearby_units = parent.spatial_grid.get_nearby_units(parent.global_position, BLOCKED_RADIUS)
	var blocking_unit = null
	for unit in nearby_units:
		if unit == parent:
			continue
		if unit.global_position.distance_to(parent.global_position) < BLOCKED_RADIUS:
			blocking_unit = unit
			break

	if blocking_unit != null:
		detour_timer += delta
		if detour_timer >= DETOUR_TIME:
			var away_dir = (parent.global_position - blocking_unit.global_position).normalized()
			var perp_dir = Vector2(-away_dir.y, away_dir.x)
			if randi() % 2 == 0:
				perp_dir = -perp_dir
			var detour_dir = (perp_dir * 0.5 + away_dir * 0.5).normalized()
			detour_target = parent.global_position + detour_dir * DETOUR_DISTANCE
			detour_timer = 0.0
			return
	else:
		detour_timer = 0.0

	# Move normally towards next path point
	var next_point = nav_agent.get_next_path_position()
	var direction = (next_point - parent.global_position).normalized()
	parent.velocity = direction * parent.get_stat("movement_speed")
	parent.move_and_slide()
	parent.handle_orientation(direction)



func _attack_move_logic(delta):
	if current_command == null:
		set_state("Idle")
		return

	aggro_check_timer += delta

	#Check enemies in aggro range every x seconds
	if aggro_check_timer >= AGGRO_CHECK_INTERVAL:
		aggro_check_timer = 0.0
		var enemy = parent.closest_enemy_in_aggro_range()
		if enemy != null:
			parent.command_component.issue_command("Attack", enemy, enemy.global_position, false, parent.owner_id)
			return

	var target_position = current_command.target_position
	var nav_agent = parent.navigation_agent

	#Calculate new path if it doesn't exist yet
	if pathfinding_target != target_position:
		nav_agent.target_position = target_position
		pathfinding_target = target_position
	
	#Target reached
	if nav_agent.is_navigation_finished():
		_process_next_command()
		return

	#Move towards the target with pathfinding
	var next_point = nav_agent.get_next_path_position()
	var direction = (next_point - parent.global_position).normalized()
	parent.velocity = direction * parent.get_stat("movement_speed")
	parent.move_and_slide()
	parent.handle_orientation(direction)

func _aggro_logic(_delta):

	var target_unit = current_command.target_unit
	if target_unit == null or !is_instance_valid(target_unit) or target_unit.dead:
		_process_next_command()
		return

	#Go to attack state if in range
	if parent.is_within_attack_range(target_unit.position):
		set_state("Attack")
		return

	#Chase if out of range
	var direction = (target_unit.global_position - parent.global_position).normalized()
	parent.velocity = direction * parent.get_stat("movement_speed")
	parent.move_and_slide()
	parent.handle_orientation(direction)
	animation_player.play("walk")
	
func _attack_logic(delta):
	
	var target_unit = current_command.target_unit
	parent.attack_target = target_unit

	if target_unit == null or !is_instance_valid(target_unit) or target_unit.dead:
		_process_next_command()
		return

	#If is in middle of an attack "Stage 2"
	if parent.is_attack_committed:
		parent.attack_anim_timer += delta

		var anim_speed = parent.get_stat("attack_speed")
		var attack_point_scaled = parent.data.unit_model_data.animation_attack_point / anim_speed
		var attack_duration_scaled = parent.data.unit_model_data.animation_attack_duration / anim_speed

		#Deal damage "Stage 3"
		if !parent.has_attacked and parent.attack_anim_timer >= attack_point_scaled:
			parent.perform_attack()
			parent.has_attacked = true

		#Finish attack animation "Stage 4"
		if parent.attack_anim_timer >= attack_duration_scaled:
			parent.attack_anim_timer = 0.0
			parent.has_attacked = false
			parent.is_attack_committed = false
	
	else:
		#Check if in range
		if parent.is_within_attack_range(target_unit.position):
			parent.velocity = Vector2.ZERO

			#Start new attack "Stage 1"
			if parent.attack_timer <= 0.0:
				parent.is_attack_committed = true
				parent.has_attacked = false
				parent.attack_anim_timer = 0.0
				parent.attack_timer = parent.get_attack_delay()

				animation_player.stop()
				animation_library.play("animations/attack")
				animation_library.speed_scale = parent.get_stat("attack_speed") + 0.05

		#Target went out of range -> Chase
		else:
			var direction = (target_unit.global_position - parent.global_position).normalized()
			parent.velocity = direction * parent.get_stat("movement_speed")
			parent.move_and_slide()
			parent.handle_orientation(direction)
			animation_player.play("walk")

func _on_death_animation_finished():
	parent.queue_free()
