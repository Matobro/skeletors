## Base class for abilities
## Holds ability_data - the data of the actual spell (name, stats etc)
## BaseAbilityType - determines how the spell is cast and behaves (targeted ability, aura, buff etc)

extends Node

class_name BaseAbility

@export var ability_data: AbilityData

var current_cooldown: float = 0.0
var ability_type: BaseAbilityType

func tick(delta: float):
	if current_cooldown > 0:
		current_cooldown = max(current_cooldown - delta, 0)

## Returns true if off cooldown and unit has enough mana to cast
func can_cast(caster) -> bool:
	return current_cooldown <= 0 and caster.data.stats.current_mana >= ability_data.mana_cost

## Called when player sends cast ability command
## Returns true or false, depending if the casting was successful
func start_cast(context: CastContext):
	# CastContext [caster, target_unit, clicked_position, ability_data]
	if !can_cast(context.caster) or !ability_type or !ability_type.is_valid_cast(context):
		return false
	
	# Casts the spell
	ability_type.cast(context)
	current_cooldown = ability_data.cooldown
	context.caster.data.stats.current_mana -= ability_data.mana_cost
	return true
