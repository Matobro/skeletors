extends StateMachine

class_name UnitAI

signal command_completed(command_type)

var last_command_type := ""
var last_commanded_position := Vector2.INF
var max_queue_size: int = 5

var current_command = null
var original_command_position = null
var pathfinding_target: Vector2 = Vector2.ZERO

var aggro_check_timer: float = 0.0
const AGGRO_CHECK_INTERVAL: float = 1.0

### Pathfinding stuff ###
var path: PackedVector2Array = []
var path_index: int = 0
var path_requested: bool = false
var current_path_request_id = 0

var last_requested_path := {"start": Vector2.INF, "end": Vector2.INF}
var last_requested_target := Vector2.ZERO
var path_request_timer := 0.0
const PATH_REQUEST_INTERVAL := 2.0  # how often u can request
const TARGET_CHANGE_THRESHOLD := 100.0  # how much target point must move to consider new path

func _ready():
	add_state("Idle")
	add_state("Move")
	add_state("Attack_move")
	add_state("Stop")
	add_state("Aggro")
	add_state("Attack")
	add_state("Dying")


func _on_command_issued(_command_type, _target, _position, is_queued):
	if !is_queued:
		if _command_type == last_command_type and _position.distance_to(last_commanded_position) < TARGET_CHANGE_THRESHOLD:
			print("Spam click detected")
			return

	last_command_type = _command_type
	last_commanded_position = _position	

	if state == "Idle" and current_command == null or !is_queued:
		_process_next_command()


func _process_next_command():
	var next_command = parent.command_component.get_next_command()

	if next_command == null:
		set_state("Idle")
		current_command = null
		last_command_type = ""
		last_commanded_position = Vector2.INF
		return

	current_command = next_command
	original_command_position = current_command.target_position
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
			aggro_check_timer = 0.0
		"Move":
			parent.spatial_grid.deregister_unit(parent)
			parent.is_moving = true
			animation_player.play("walk")
		"Attack_move":
			parent.spatial_grid.deregister_unit(parent)
			aggro_check_timer = 0.0
			animation_player.play("walk")
		"Aggro":
			parent.spatial_grid.deregister_unit(parent)
			animation_player.play("walk")
		"Attack":
			parent.spatial_grid.deregister_unit(parent)
			parent.velocity = Vector2.ZERO
		"Dying":
			parent.spatial_grid.deregister_unit(parent)
			parent.set_physics_process(false)
			parent.set_collision_layer(0)
			parent.set_collision_mask(0)
			animation_player.connect("animation_finished", Callable(self, "_on_death_animation_finished"), CONNECT_ONE_SHOT)
			animation_player.play("dying")
		"Stop":
			parent.spatial_grid.update_unit_position(parent)
			parent.velocity = Vector2.ZERO
			_process_next_command()


func exit_state(_old_state, _new_state):
	match _old_state:
		"Move":
			path = []
			path_index = 0
			path_requested = false
			last_requested_target = Vector2.ZERO
			parent.spatial_grid.register_unit(parent)
			parent.velocity = Vector2.ZERO
			parent.is_moving = false
			parent.navigation_agent.set_velocity(Vector2.ZERO)
			animation_player.stop()
		"Aggro":
			parent.spatial_grid.register_unit(parent)
			parent.is_moving = false
			parent.navigation_agent.set_velocity(Vector2.ZERO)
			animation_player.stop()
		"Attack":
			parent.spatial_grid.register_unit(parent)
			parent.is_moving = false
			parent.navigation_agent.set_velocity(Vector2.ZERO)


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

	if aggro_check_timer > AGGRO_CHECK_INTERVAL:
		aggro_check_timer = 0.0
		var enemy = parent.closest_enemy_in_aggro_range()
		if enemy != null:
			parent.command_component.issue_command("Attack", enemy, enemy.global_position, false, parent.owner_id)


func _move_logic(_delta):
	if current_command == null:
		set_state("Idle")
		return

	var target = current_command.target_position
	var spatial_grid = parent.spatial_grid

	# If we have no path yet
	if path.size() == 0:
		if not path_requested:
			# Debounce: if target is basically the same as before, don't re-request
			if last_requested_target.distance_to(target) < TARGET_CHANGE_THRESHOLD:
				print("Overriding")
				# Skip requesting a new path; treat as already handled
				_process_next_command()
				return

			last_requested_target = target
			current_path_request_id += 1
			spatial_grid.queue_unit_for_path(parent, current_path_request_id)
			path_requested = true
		return  # Wait for path

	# Reached end
	if path_index >= path.size():
		_process_next_command()
		path_requested = false
		return

	var _target = path[path_index]
	var to_target = _target - parent.global_position

	if to_target.length() < 10.0:
		path_index += 1
	else:
		var dir = to_target.normalized()
		var velocity = dir * parent.get_stat("movement_speed")
		parent.velocity = velocity
		parent.move_and_slide()

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

	path = new_path
	path_index = 0
	path_requested = false

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
