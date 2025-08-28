extends Node
class_name UnitCombatState

var ai
var parent

var current_target: Node = null
var current_target_previous
var attack_timer: float = 0.0
var aggro_timer: float = 0.0
var attack_anim_timer: float = 0.0
var time_since_start: float = 0.0
var is_attack_committed: bool
var has_attacked: bool

var target_switch_cooldown: float = 0.5 
var time_since_last_switch: float = 0.0

var recent_attackers: Array[Dictionary] = []

const ATTACKER_MEMORY := 1.5
const AGGRO_CHECK_INTERVAL := 0.5

func _init(_ai, _parent):
	ai = _ai
	parent = _parent

func update(delta: float) -> void:
	time_since_last_switch += delta
	time_since_start += delta
	aggro_timer += delta
	attack_timer = max(attack_timer - delta, 0.0)
	clean_recent_attackers()

	if is_player_controlled() and ai.state not in ["Attack_move"]:
		print("lolo")
		set_target_from_player_command()
	else:
		acquire_target_ai()

func is_player_controlled() -> bool:
	var cmd = ai.command_handler.current_command
	return cmd != null and cmd.has("is_player_command") and cmd.is_player_command

func set_target_from_player_command():
	var cmd = ai.command_handler.current_command
	if cmd != {} and cmd.has("target_unit") and is_valid_target(cmd.target_unit):
		current_target = cmd.target_unit
		ai.parent.unit_visual.set_target(current_target)
	else:
		current_target = null
		ai.parent.unit_visual.clear_target()

func acquire_target_ai():
	var new_target: Node = null

	# Check recent attackers
	for record in recent_attackers:
		var attacker = record.attacker
		if is_valid_target(attacker):
			new_target = attacker
			break

	# If no recent attacker check aggro
	if new_target == null and aggro_timer >= AGGRO_CHECK_INTERVAL:
		aggro_timer = 0.0
		var enemy = parent.unit_combat.closest_enemy_in_aggro_range()
		if is_valid_target(enemy):
			new_target = enemy

	# Decide if switch target
	if new_target != null and should_switch_target(new_target):
		clear_attack_state()
		current_target = new_target
		ai.parent.unit_visual.set_target(current_target)
		time_since_last_switch = 0.0

func should_switch_target(new_target: Node) -> bool:
	if !is_valid_target(current_target):
		return true  # always switch if no current target

	if time_since_last_switch < target_switch_cooldown:
		return false  # dont switch too quickly

	# Switch if new target is closer (with buffer)
	var current_dist = parent.global_position.distance_to(current_target.global_position)
	var new_dist = parent.global_position.distance_to(new_target.global_position)
	return new_dist + 64 < current_dist

func on_attacked_by(attacker: Node):
	if !is_valid_target(attacker):
		return
	recent_attackers.append({"attacker": attacker, "time": time_since_start})

func clean_recent_attackers():
	recent_attackers = recent_attackers.filter(
		func(record): return time_since_start - record.time < ATTACKER_MEMORY
	)

func is_valid_target(target) -> bool:
	return target != null and is_instance_valid(target) and !target.unit_combat.dead

func clear_attack_state():
	attack_anim_timer = 0.0
	is_attack_committed = false
	has_attacked = false

func clear_combat_state():
	current_target = null
	attack_anim_timer = 0.0
	recent_attackers.clear()
	ai.parent.unit_visual.clear_target()
