## Manages unit abilities
## Parent is the actual unit
## Data is the units data - stats, model
## Only heroes have spells btw

extends Node

class_name UnitAbilityManager

var abilities: Array[BaseAbility]

var parent
var data
var spell_being_cast: BaseAbility
var casting: bool = false

func _init(parent_ref, data_ref) -> void:
	parent = parent_ref
	data = data_ref

	for ability in data.abilities:
		add_ability(ability)

func tick(delta: float):
	for ability in abilities:
		ability.tick(delta)
		
func cast_ability(context: CastContext):
	spell_being_cast = context.ability
	casting = true
	abilities[context.index].start_cast(context)

## Adds ability to unit via [AbilityData]
func add_ability(ability_data: AbilityData):
	var ability = AbilitySystem.create_ability(ability_data, parent)
	if ability:
		abilities.append(ability)
	else:
		print("Couldnt add ability with data: ", ability_data)
