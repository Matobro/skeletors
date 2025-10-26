## Base class for abilities
## Holds ability_data - the data of the actual spell (name, stats etc)
## BaseAbilityType - determines how the spell is cast and behaves (targeted ability, aura, buff etc)

extends Node

class_name BaseAbility

@export var ability_data: AbilityData

var current_cooldown: float = 0.0
var cast_timer: float = 0.0
var currently_casting: bool = false
var current_cast: CastContext

var parent

signal cast_done()

func _init(data, source_unit) -> void:
	ability_data = data
	parent = source_unit
	# If passive, cast it immediately to activate it
	if data.is_passive:
		var context = CastContext.new()
		context.caster = source_unit
		context.ability = self
		ability_data.ability_type.cast(context)
	
func tick(delta: float):
	if ability_data.is_passive:
		return

	if current_cooldown > 0:
		current_cooldown = max(current_cooldown - delta, 0)
	if currently_casting:
		channel_ability(delta)

## Returns true if off cooldown and unit has enough mana to cast
func can_cast(context) -> bool:
	return current_cooldown <= 0 and context.caster.data.stats.current_mana >= ability_data.mana_cost and !currently_casting

func is_valid_cast(context) -> bool:
	return ability_data.ability_type and ability_data.ability_type.is_valid_cast(context)

func get_stat_scaling(stat_name: String) -> float:
	if !ability_data.stat_scaling.has(stat_name):
		return 0.0
	var base_scaling = ability_data.stat_scaling[stat_name]
	var stat_value = parent.data.get_stat(stat_name)
	return base_scaling * stat_value

## Called when player sends cast ability command
## Returns true or false, depending if the casting was successful
func start_cast(context: CastContext):
	if !can_cast(context):
		emit_signal("cast_done")
		return
	
	# Start casting the ability
	current_cast = context
	cast_timer = ability_data.cast_time
	currently_casting = true

func channel_ability(delta):
	if !current_cast:
		currently_casting = false
		return

	cast_timer -= delta

	if cast_timer <= 0:
		execute_ability(current_cast)
		current_cast = null

func execute_ability(context: CastContext):
	currently_casting = false
	ability_data.ability_type.cast(context)
	current_cooldown = ability_data.cooldown
	context.caster.data.stats.current_mana -= ability_data.mana_cost
	parent.unit_ability_manager.casting = false
	emit_signal("cast_done")
	pass

func cancel_cast():
	current_cast = null
	currently_casting = false
	parent.unit_ability_manager.casting = false
