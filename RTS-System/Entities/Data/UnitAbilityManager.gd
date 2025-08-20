extends Node

class_name UnitAbilityManager

var abilities: Array[Ability]

var parent
var data

func _init(parent_ref, data_ref) -> void:
	parent = parent_ref
	data = data_ref

	if data.unit_type == "hero":
		var rof = load("res://RTS-System/Abilities/Resources/Rain of Fire.tres")
		abilities.append(rof)

		var shockwave = load("res://RTS-System/Abilities/Resources/Shockwave.tres")
		abilities.append(shockwave)

func cast_ability(index: int, pos: Vector2, world_node: Node):
	if index < 0 or index >= abilities.size():
		return

	var ability = abilities[index]
	var ability_instance = ability.activate_ability(pos, world_node, parent)

	if ability_instance != null:
		world_node.add_child(ability_instance)
