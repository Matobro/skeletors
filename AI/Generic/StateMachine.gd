extends Node

class_name StateMachine

var state_id: int = 0
var state: String = ""
var prev_state = null
var states = {}
var initialized: bool = false

@onready var parent = get_parent()
var animation_player = null
var animation_library = null

func set_ready():
	initialized = true
	set_state("Idle")

func _physics_process(delta):
	if !initialized:
		return

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
	
