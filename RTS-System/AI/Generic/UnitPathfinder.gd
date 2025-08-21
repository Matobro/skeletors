extends Node

class_name UnitPathfinder

var ai
var parent

# Path state
var path: Array = []
var path_index: int = 0
var path_requested: bool = false
var current_request_id: int = 0

# Target tracking
var last_requested_path := {"start": Vector2.INF, "end": Vector2.INF, "status": "none"}
var last_requested_target: Vector2 = Vector2.ZERO

# Timers
var path_timeout_timer: float = 0.0
var stuck_check_timer: float = 0.0
var last_position: Vector2 = Vector2.INF

# Constants
const PATH_TIMEOUT := 1.5
const STUCK_TIME_THRESHOLD := 1.0
const STUCK_DISTANCE_THRESHOLD := 10.0
const PATH_RECALC_THRESHOLD := 40.0

func _init(unit_ai):
	ai = unit_ai
	parent = ai.parent
	SpatialGrid.path_request_manager.path_ready.connect(on_path_ready)

func reset():
	path.clear()
	path_index = 0
	path_requested = false
	current_request_id = 0
	last_requested_path = {"start": Vector2.INF, "end": Vector2.INF, "status": "none"}
	last_requested_target = Vector2.ZERO
	path_timeout_timer = 0.0
	stuck_check_timer = 0.0
	last_position = Vector2.INF

func request_path() -> void:
	if path_requested:
		return

	if ai.get_current_command() == {}:
		return

	var target = ai.get_current_command().target_position
	path_requested = true
	path_timeout_timer = 0.0
	current_request_id += 1
	SpatialGrid.queue_unit_for_path(parent, current_request_id, target)
	last_requested_path = {"start": parent.global_position, "end": target, "status": "requested"}

func get_walk_animation_speed() -> float:
	var scale = parent.get_stat("movement_speed") / 330.0
	var animation_speed = pow(scale, StatModifiers.movement_speed_animation_modifier)
	return animation_speed

func follow_path(delta: float) -> void:
	ai.animation_player.play_animation("walk", get_walk_animation_speed())

	# Request path if no path yet
	if path.size() <= 0:
		request_path()
		ai.animation_player.stop()
		return

	# Check if reached end
	if path_index >= path.size():
		path_requested = false
		ai.animation_player.stop()
		return

	# Movement logic
	var next_point: Vector2 = path[path_index]
	var dir: Vector2 = (next_point - parent.global_position).normalized()
	parent.velocity = dir * parent.get_stat("movement_speed")
	parent.move_and_slide()
	parent.unit_visual.handle_orientation(dir)

	# Waypoint reached
	if parent.global_position.distance_to(next_point) < 10:
		path_index += 1

	# Timeout check if waiting for a path
	if path_requested:
		path_timeout_timer += delta
		if path_timeout_timer >= PATH_TIMEOUT:
			print("Path request timed out, retrying")
			path_requested = false
			request_path()

	# Stuck check
	_check_stuck(delta)
	SpatialGrid.update_unit_position(parent)

func on_path_ready(unit: Unit, new_path: PackedVector2Array, request_id: int) -> void:
	if request_id != current_request_id or new_path.size() <= 0 or unit != parent:
		path_requested = false
		return 

	path = new_path
	path_index = 0
	path_requested = false
	last_requested_path.status = "ready"
	print("Path received with %d waypoints" % path.size())

	SpatialGridDebugRenderer._receive_path(unit, path)

func _check_stuck(delta: float) -> void:
	stuck_check_timer += delta

	if last_position == Vector2.INF:
		last_position = parent.global_position
		return

	if stuck_check_timer >= STUCK_TIME_THRESHOLD:
		var moved = parent.global_position.distance_to(last_position)
		if moved < STUCK_DISTANCE_THRESHOLD:
			print("Unit stuck, requesting path")
			path_requested = false
			request_path()

		stuck_check_timer = 0.0
		last_position = parent.global_position
