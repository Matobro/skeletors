extends StateMachine

class_name UnitAI

signal command_completed(command_type, fallback_command)

var current_command = null
var fallback_command = null

var aggro_check_timer: float = 0.0
const AGGRO_CHECK_INTERVAL: float = 1.0

### Pathfinding stuff ###
var path: PackedVector2Array = []
var path_index: int = 0
var path_requested: bool = false
var current_path_request_id = 0
var dont_clear: bool

var last_requested_path := {"start": Vector2.INF, "end": Vector2.INF, "status": "none"}
var last_requested_target := Vector2.ZERO

var path_timeout_timer = 0.0
const PATH_REQUEST_TIMEOUT = 1.0

### Stuck stuff ###
var stuck_check_timer: float = 0.0
var last_position: Vector2 = Vector2.INF
const STUCK_TIME_THRESHOLD: float = 0.5
const STUCK_DISTANCE_THRESHOLD: float = 10.0

var devstate: Label = null

func _ready():
	add_state("Idle", preload("res://RTS-System/AI/Generic/UnitAIStates/IdleState.gd").new())
	add_state("Move", preload("res://RTS-System/AI/Generic/UnitAIStates/MoveState.gd").new())
	add_state("Attack_move", preload("res://RTS-System/AI/Generic/UnitAIStates/AttackMoveState.gd").new())
	add_state("Aggro", preload("res://RTS-System/AI/Generic/UnitAIStates/AggroState.gd").new())
	add_state("Attack", preload("res://RTS-System/AI/Generic/UnitAIStates/AttackState.gd").new())
	add_state("Hold", preload("res://RTS-System/AI/Generic/UnitAIStates/HoldState.gd").new())
	add_state("Stop", preload("res://RTS-System/AI/Generic/UnitAIStates/StopState.gd").new())
	add_state("Dying", preload("res://RTS-System/AI/Generic/UnitAIStates/DyingState.gd").new())
	devstate = $"../DevState"

	for s in states.values():
		s.ai = self
		s.parent = parent

func _on_command_issued(_command_type, _target, _position, is_queued):
	if !is_queued:
		_process_next_command()

func special_process():
	devstate.text = state

func _process_next_command():
	if parent.data.unit_type == "neutral":
		return
	
	dont_clear = false
	var next_command = parent.command_component.get_next_command()

	## Go idle if no next command
	if next_command == null:
		set_state("Idle")
		current_command = null
		return

	if is_spam(next_command):
		dont_clear = true
		parent.command_component.remove_command(next_command)
		return

	## Get next command
	current_command = next_command
	parent.command_component.pop_next_command()

	## Signal previous command as completed
	emit_signal("command_completed", current_command.type, fallback_command)

	dont_clear = false

	## Set state from command
	match current_command.type:
		"Move":
			set_state("Move")
		"Attack":
			set_state("Aggro")
		"Attack_move":
			set_state("Attack_move")
		"Stop":
			set_state("Stop")
		"Hold":
			set_state("Hold")
		_:
			set_state("Idle")

func is_spam(next_command):
	if next_command != null and current_command != null:
		if next_command.type == current_command.type and next_command.target_position.distance_to(current_command.target_position) <= 50:
			return true
		
	return false

func clear_unit_state():
	if dont_clear:
		return
	
	aggro_check_timer = 0.0

	path = []
	path_index = 0
	path_requested = false
	current_path_request_id = 0

	last_requested_path = {"start": Vector2.INF, "end": Vector2.INF, "status": "none"}
	last_requested_target = Vector2.ZERO

	path_timeout_timer = 0.0

	stuck_check_timer = 0.0
	last_position = Vector2.INF

	parent.attack_anim_timer = 0.0
	parent.is_attack_committed = false

func request_path(delta):
	if path_requested:
		path_timeout_timer += delta
		if path_timeout_timer >= PATH_REQUEST_TIMEOUT:
			print("Timeout waiting for path. Retrying...")
			clear_unit_state()
		else:
			return

	print("Path requested")
	current_path_request_id += 1

	path_requested = true
	path_timeout_timer = 0.0
	
	last_position = parent.global_position
	stuck_check_timer = 0.0
	SpatialGrid.queue_unit_for_path(parent, current_path_request_id, current_command.target_unit)
	SpatialGridDebugRenderer._delete_path(parent)

func _on_path_ready(unit, new_path: PackedVector2Array, request_id):
	# Path for wrong unit (how)
	if unit != parent:
		return

	# Return if outdated path (someone likes spamming clicks)
	if request_id != current_path_request_id:
		return
	
	path_requested = false

	# Return if invalid path
	if new_path.size() == 0:
		return

	# Setup received path
	path = new_path
	path_index = 0
	path_timeout_timer = 0.0

	last_requested_path = {
		"start": parent.global_position,
		"end": current_command.target_position if current_command != null else parent.global_position,
		"status": "received"
	}

	#DEBUG
	SpatialGridDebugRenderer._receive_path(unit, path)

func _follow_path(delta):

	if path.size() <= 0:
		return

	## Reached end
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
		var final_direction = dir.normalized()
		var desired_velocity = final_direction * parent.get_stat("movement_speed")
		parent.velocity = parent.velocity.lerp(desired_velocity, 0.7) # the magic number is "acceleration", high values introduce jittering, low values makes units floaty
		parent.move_and_slide()
		parent.handle_orientation(final_direction)

		# Stuck detection
		stuck_check_timer += delta

		if last_position == Vector2.INF:
			last_position = parent.global_position

		elif stuck_check_timer >= STUCK_TIME_THRESHOLD:
			var moved_distance = parent.global_position.distance_to(last_position)
			if moved_distance < STUCK_DISTANCE_THRESHOLD:
				print("Unit is stuck")
				request_path(delta)

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
