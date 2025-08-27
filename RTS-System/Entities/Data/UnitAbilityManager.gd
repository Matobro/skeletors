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
		
func cast_ability(index, pos, target):
	print("casting ",abilities[index], " at ", pos, " target: ", target)
	abilities[index].start_cast(parent, pos, target)

func add_ability(ability_data: AbilityData):
	var ability = BaseAbility.new()
	add_child(ability)
	ability.ability_data = ability_data
	abilities.append(ability)