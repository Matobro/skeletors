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

		var defaura = preload("res://AbilitySystem/Abilities/Defensive Aura.tres")
		add_ability(defaura)

func tick(delta: float):
	for ability in abilities:
		ability.tick(delta)
		
func cast_ability(context: CastContext):
	abilities[context.index].start_cast(context)

## Adds ability to unit via [AbilityData]
func add_ability(ability_data: AbilityData):
	var ability = AbilitySystem.create_ability(ability_data, parent)
	if ability:
		abilities.append(ability)
	else:
		print("Couldnt add ability with data: ", ability_data)
