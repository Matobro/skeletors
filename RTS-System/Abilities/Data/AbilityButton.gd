extends Button

var ability: Ability
var unit_ref: Node
var index: int

func setup(ability_data: Ability, unit: Node, slot_index: int):
	ability = ability_data
	unit_ref = unit
	index = slot_index
	icon = ability.icon

func _pressed():
	if unit_ref:
		unit_ref.cast_ability(index, get_global_mouse_position(), get_tree().current_scene)
