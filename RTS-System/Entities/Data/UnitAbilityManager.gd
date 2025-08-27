## Manages unit abilities
## Parent is the actual unit
## Data is the units data - stats, model
## Only heroes have spells btw

extends Node

class_name UnitAbilityManager

var abilities: Array[BaseAbility]

var parent
var data

func _init(parent_ref, data_ref) -> void:
	parent = parent_ref
	data = data_ref

	if parent is Hero:
		var fireball = preload("res://AbilitySystem/Abilities/Fireball.tres")
		add_ability(fireball)

func tick(delta: float):
	for ability in abilities:
		ability.tick(delta)
		
func cast_ability(index, target_position, target_unit):
	var context = CastContext.new()
	context.caster = parent
	context.ability_data = abilities[index].ability_data
	context.target_position = target_position
	context.target_unit = target_unit

	abilities[index].start_cast(context)

## Adds ability to unit via [AbilityData]
func add_ability(ability_data: AbilityData):
	var ability = AbilitySystem.create_ability(ability_data)
	if ability:
		abilities.append(ability)
	else:
		print("Couldnt add ability with data: ", ability_data)
