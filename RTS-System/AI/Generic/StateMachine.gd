extends Node

class_name StateMachine

var state: String = ""
var prev_state: String = ""
var states: Dictionary = {}
var current_state = null
var initialized: bool = false

@onready var parent = get_parent()
var animation_player = null

func set_ready():
	initialized = true
	if "Idle" in states:
		set_state("Idle")

func _physics_process(delta):
	if !initialized or current_state == null:
		return
	current_state.state_logic(delta)
	special_process()
	
func special_process():
	pass
func set_state(new_state: String):

	if current_state != null:
		current_state.exit_state()

	prev_state = state
	state = new_state
	current_state = states.get(new_state)

	if current_state != null:
		current_state.enter_state()

func add_state(_name: String, state_instance):
	states[_name] = state_instance
	state_instance.ai = self
	state_instance.parent = parent
