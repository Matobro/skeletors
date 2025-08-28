## Base class for abilities
## Holds ability_data - the data of the actual spell (name, stats etc)
## BaseAbilityType - determines how the spell is cast and behaves (targeted ability, aura, buff etc)

extends Node

class_name BaseAbility

@export var ability_data: AbilityData

var current_cooldown: float = 0.0
var cast_timer: float = 0.0
var ability_type: BaseAbilityType
var currently_casting: bool = false
var current_cast: CastContext

signal cast_done()

func tick(delta: float):
	if current_cooldown > 0:
		current_cooldown = max(current_cooldown - delta, 0)
	if currently_casting:
		channel_ability(delta)

## Returns true if off cooldown and unit has enough mana to cast
func can_cast(caster) -> bool:
	return current_cooldown <= 0 and caster.data.stats.current_mana >= ability_data.mana_cost and !currently_casting

## Called when player sends cast ability command
## Returns true or false, depending if the casting was successful
func start_cast(context: CastContext):
	# CastContext [caster, target_unit, clicked_position, ability_data]
	if !can_cast(context.caster) or !ability_type or !ability_type.is_valid_cast(context):
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
	ability_type.cast(context)
	current_cooldown = ability_data.cooldown
	context.caster.data.stats.current_mana -= ability_data.mana_cost
	emit_signal("cast_done")
	pass