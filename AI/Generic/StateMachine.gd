extends Node

class_name StateMachine

var state: String = ""
var prev_state = null
var states = {}

@onready var parent = get_parent()

func _physics_process(delta):
	var new_state = get_transition(delta)
	if new_state != null:
		set_state(new_state)
	state_logic(delta)
			
func state_logic(delta):
	pass
	
func get_transition(delta):
	pass
	
func enter_state(new_state, old_state):
	pass
	
func exit_state(old_state, new_state):
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
	
