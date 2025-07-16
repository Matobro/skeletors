extends Node

class_name StateMachine

var frame_counter := 0
const FRAME_INTERVAL := 2

var state_id: int = 0
var state: String = ""
var prev_state = null
var states = {}

var restrict_speed: bool = false

@onready var parent = get_parent()
@onready var animation_player = get_parent().get_node("AnimatedSprite2D")

func _physics_process(delta):
	if restrict_speed:
		frame_counter += 1
		if frame_counter >= FRAME_INTERVAL:
			frame_counter = 0
			update_state_machine(delta)
	else:
		update_state_machine(delta)
			
func update_state_machine(delta):
	var new_state = get_transition(delta)
	if new_state != null:
		set_state(new_state)
	state_logic(delta)
	
func state_logic(_delta):
	pass
	
func get_transition(_delta):
	pass
	
func enter_state(_new_state, _old_state):
	pass
	
func exit_state(_old_state, _new_state):
	pass
	
func set_state(new_state: String):
	prev_state = state
	state = new_state
	
	if prev_state != null:
		exit_state(prev_state, new_state)
	if new_state != null:
		enter_state(new_state, prev_state)

func add_state(state_name):
	states[state_name] = state_name
	
func get_state():
	pass
	
