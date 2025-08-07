extends Node

@export var abilities: Array[Ability] = []

func add_ability(ability: Ability):
    ability.owner = get_parent()
    abilities.append(ability)

func activate_ability(index: int, target = null, position = Vector2.ZERO):
    if index < 0 or index >= abilities.size():
        return
    abilities[index].activate_ability(target, position, abilities[index].owner)