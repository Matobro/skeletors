extends Node

@onready var ability_grid = $AbilityButtons

var ability_slots = []

func _ready() -> void:
	for slot in ability_grid.get_children(false):
		ability_slots.append(slot)

func update_action_menu(abilities: Array[BaseAbility] = []):
	clear_abilities()

	if abilities:
		for i in range(abilities.size()):
			ability_slots[i].set_slot(abilities[i], abilities[i].ability_data)

func clear_abilities():
	for slot in ability_slots:
		slot.set_slot(null, null)
