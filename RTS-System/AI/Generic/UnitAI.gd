extends StateMachine
class_name UnitAI

var pathfinder: UnitPathfinder
var command_handler: UnitCommandHandler
var combat_state: UnitCombatState

func init_ai():
	pathfinder = UnitPathfinder.new(self)
	command_handler = UnitCommandHandler.new(self, holder)
	combat_state = UnitCombatState.new(self, parent)

	add_child(pathfinder)
	add_child(command_handler)
	add_child(combat_state)

	init_states()

func init_states():
	add_state("Idle", preload("res://RTS-System/AI/Generic/UnitAIStates/IdleState.gd").new())
	add_state("Move", preload("res://RTS-System/AI/Generic/UnitAIStates/MoveState.gd").new())
	add_state("Attack_move", preload("res://RTS-System/AI/Generic/UnitAIStates/AttackMoveState.gd").new())
	#add_state("Aggro", preload("res://RTS-System/AI/Generic/UnitAIStates/AggroState.gd").new())
	add_state("Attack", preload("res://RTS-System/AI/Generic/UnitAIStates/AttackState.gd").new())
	add_state("Hold", preload("res://RTS-System/AI/Generic/UnitAIStates/HoldState.gd").new())
	add_state("Stop", preload("res://RTS-System/AI/Generic/UnitAIStates/StopState.gd").new())
	add_state("Dying", preload("res://RTS-System/AI/Generic/UnitAIStates/DyingState.gd").new())

	for s in states.values():
		s.ai = self
		s.parent = parent
	
	set_ready()

## Returns current command:
## command_type [string], target [Unit], position [Vector2], is_queued [bool]
func get_current_command() -> Dictionary:
	var cmd = command_handler.current_command
	return cmd if cmd != null else {}

func _on_death_animation_finished():
	parent.queue_free()
