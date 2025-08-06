extends StateMachine

#class_name UnitAI

signal command_completed(command_type)

var current_command = null
var fallback_command = null

var aggro_check_timer: float = 0.0
const AGGRO_CHECK_INTERVAL: float = 1.0

### Pathfinding stuff ###
var path: PackedVector2Array = []
var path_index: int = 0
var path_requested: bool = false
var current_path_request_id = 0

var last_requested_path := {"start": Vector2.INF, "end": Vector2.INF}
var last_requested_target := Vector2.ZERO

### Stuck stuff ###
var stuck_check_timer: float = 0.0
var last_position: Vector2 = Vector2.INF
const STUCK_TIME_THRESHOLD: float = 0.5
const STUCK_DISTANCE_THRESHOLD: float = 5.0

var devstate = null

func _ready():
	add_state("Idle")
	add_state("Move")
	add_state("Hold")
	add_state("Attack_move")
	add_state("Stop")
	add_state("Aggro")
	add_state("Attack")
	add_state("Dying")
	devstate = $"../DevState"


func _on_command_issued(_command_type, _target, _position, is_queued):
	if !is_queued:
		_process_next_command()

func _process_next_command():
	var next_command = parent.command_component.get_next_command()

	if next_command == null:
		set_state("Idle")
		current_command = null
		return

	current_command = next_command
	parent.command_component.pop_next_command()

	emit_signal("command_completed", current_command.type)

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
	if !initialized:
		return

	match _new_state:
		"Idle":
			animation_player.play("idle")
			parent.velocity = Vector2.ZERO
			aggro_check_timer = AGGRO_CHECK_INTERVAL
			SpatialGridDebugRenderer._delete_path(parent)
		"Move":
			path = []
			SpatialGrid.deregister_unit(parent)
			parent.is_moving = true
			animation_player.play("walk")
		"Hold":
			SpatialGrid.update_unit_position(parent)
			parent.velocity = Vector2.ZERO
			animation_player.play("idle")
			parent.is_holding_position = true
		"Attack_move":
			SpatialGrid.deregister_unit(parent)
			aggro_check_timer = AGGRO_CHECK_INTERVAL
			animation_player.play("walk")
		"Aggro":
			SpatialGrid.deregister_unit(parent)
			SpatialGrid.deregister_unit(parent)
			animation_player.play("walk")
			last_requested_target = Vector2.INF
		"Attack":
			SpatialGrid.deregister_unit(parent)
			parent.velocity = Vector2.ZERO
		"Dying":
			SpatialGrid.deregister_unit(parent)
			parent.set_physics_process(false)
			parent.set_collision_layer(0)
			parent.set_collision_mask(0)
			animation_player.connect("animation_finished", Callable(self, "_on_death_animation_finished"), CONNECT_ONE_SHOT)
			animation_player.play("dying")
		"Stop":
			SpatialGrid.update_unit_position(parent)
			parent.velocity = Vector2.ZERO
			_process_next_command()


func exit_state(_old_state, _new_state):
	match _old_state:
		"Move":
			path = []
			path_index = 0
			path_requested = false
			last_requested_target = Vector2.ZERO
			SpatialGrid.register_unit(parent)
			parent.velocity = Vector2.ZERO
			animation_player.stop()
		"Attack_move":
			path = []
			path_index = 0
			path_requested = false
			last_requested_target = Vector2.ZERO
			SpatialGrid.register_unit(parent)
			parent.velocity = Vector2.ZERO
			animation_player.stop()
		"Aggro":
			path = []
			path_index = 0
			path_requested = false
			last_requested_target = Vector2.ZERO
			SpatialGrid.register_unit(parent)
			animation_player.stop()
		"Attack":
			SpatialGrid.register_unit(parent)
		"Hold":
			parent.is_holding_position = false


func state_logic(delta):
	devstate.text = state
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
		_process_next_command()
		return

	parent.velocity = Vector2.ZERO
	aggro_check_timer += delta

	# Check enemies in aggro range every x seconds
	if aggro_check_timer > AGGRO_CHECK_INTERVAL:
		aggro_check_timer = 0.0
		var enemy = parent.closest_enemy_in_aggro_range()

		# If enemy found, issue attack command to that unit
		if enemy != null:
			parent.command_component.issue_command("Attack", enemy, enemy.global_position, false, parent.owner_id)

func _move_logic(delta):
	if current_command == null:
		set_state("Idle")
		return

	# If no path, request path
	if path.size() <= 0:
		request_path()
		return # wait for path

	# Follow path
	_follow_path(delta)

func _attack_move_logic(delta):
	if current_command == null:
		set_state("Idle")
		return

	# Check for enemies in aggro range every x seconds
	aggro_check_timer += delta
	if aggro_check_timer >= AGGRO_CHECK_INTERVAL:
		aggro_check_timer = 0.0
		var enemy = parent.closest_enemy_in_aggro_range()
		if enemy != null:
			fallback_command = current_command
			parent.command_component.issue_command("Attack", enemy, enemy.global_position, false, parent.owner_id)
			return

	# If no path, request path
	if path.size() <= 0:
		request_path()
		return # wait for path

	# Follow path
	_follow_path(delta)

func _aggro_logic(delta):
	
	var target_unit = current_command.target_unit
	if target_unit == null or !is_instance_valid(target_unit) or target_unit.dead:
		_process_next_command()
		return

	# If in attack range then go to attack state
	if parent.is_within_attack_range(target_unit.global_position):
		set_state("Attack")
		return

	current_command.target_position = target_unit.global_position
			
	# If no path, request path
	if path.size() <= 0:
		request_path()
		return # wait for path
		
	# Else follow path
	_follow_path(delta)
		
	# If target moved over x amount then get new path
	if path.size() > 0:
		var target_cell = SpatialGrid.get_cell_coords(target_unit.global_position)
		var path_end_cell = SpatialGrid.get_cell_coords(path[-1])
		if target_cell.distance_to(path_end_cell) > 1:
			request_path()

	# If reached end of path -> "nudge" them closer
	if path_index >= path.size() and !parent.is_within_attack_range(target_unit.global_position):
		var dir = (target_unit.global_position - parent.global_position).normalized()
		parent.velocity = dir * parent.get_stat("movement_speed") * 0.5
		parent.move_and_slide()
		parent.handle_orientation(dir)

func _attack_logic(delta):
	
	var target_unit = current_command.target_unit
	parent.attack_target = target_unit

	# Check if target is still valid
	if target_unit == null or !is_instance_valid(target_unit) or target_unit.dead:
		if fallback_command != null:
			current_command = fallback_command
			fallback_command = null
			if current_command.type == "Attack_move":
				set_state("Attack_move")
			else:
				_process_next_command()
		else:
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
			set_state("Aggro")

func apply_separation_force() -> Vector2:
	if parent.is_holding_position:
		return Vector2.ZERO
	
	var force = Vector2.ZERO
	var nearby_units = SpatialGrid.get_units_around(parent.global_position, 32)

	for other in nearby_units:
		if other == parent:
			continue
		if other.is_holding_position:
			continue
		
		var offset = parent.global_position - other.global_position
		var dist = offset.length()
		if dist > 0 and dist < 32:
			force += offset.normalized() / dist  # stronger when closer

	return force.normalized()

func request_path():
	current_path_request_id += 1
	path_requested = true
	SpatialGrid.queue_unit_for_path(parent, current_path_request_id, current_command.target_unit)
	SpatialGridDebugRenderer._delete_path(parent)

func _on_path_ready(unit, new_path: PackedVector2Array, request_id):
	# Path for wrong unit (how)
	if unit != parent:
		return

	# Return if outdated path (someone likes spamming clicks)
	if request_id != current_path_request_id:
		return

	# Return if invalid path
	if new_path.size() == 0:
		set_state("Idle")
		return
	
	# Setup received path
	path = new_path
	path_index = 0
	path_requested = false

	#DEBUG
	SpatialGridDebugRenderer._receive_path(unit, path)

func _follow_path(_delta):
	if path.size() <= 0:
		return

	if path_index >= path.size():
		path_requested = false
		stuck_check_timer = 0.0  # reset stuck timer when path finished
		last_position = Vector2.INF
		return

	var _target = path[path_index]
	var distance_to_target = _target - parent.global_position

	# Check if distance to current path point is close enough
	if distance_to_target.length() < 10.0:
		path_index += 1

	else:
		# Movement logic
		var dir = distance_to_target.normalized()
		var separation = apply_separation_force()
		var final_direction = (dir + separation * 0.75).normalized()
		parent.velocity = final_direction * parent.get_stat("movement_speed")
		parent.move_and_slide()
		parent.handle_orientation(final_direction)

		# --- Stuck detection logic ---
		stuck_check_timer += _delta

		if last_position == Vector2.INF:
			last_position = parent.global_position

		elif stuck_check_timer >= STUCK_TIME_THRESHOLD:
			var moved_distance = parent.global_position.distance_to(last_position)
			if moved_distance < STUCK_DISTANCE_THRESHOLD:
				print("Unit seems stuck. Requesting new path.")
				request_path()
				stuck_check_timer = 0.0
				last_position = parent.global_position
			else:
				# Reset timer and last position if progress was made
				stuck_check_timer = 0.0
				last_position = parent.global_position

	# Check if distance to end goal is close enough
	var distance_to_goal = parent.global_position.distance_to(path[-1])

	if distance_to_goal < 10.0:
		if current_command != null and current_command.type in ["Attack", "Attack_move"]:
			return
		_process_next_command()

func _on_death_animation_finished():
	parent.queue_free()
