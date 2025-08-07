extends Resource

class_name Ability

@export var name: String = ""
@export var icon: Texture2D

@export var cooldown: float = 0.0
@export var mana_cost: int

@export var fx: FXResource

func activate_ability(_position: Vector2, _world_node: Node, _caster_owner: Node) -> Node:
    push_error("activate_ability() isn't implemented in " + str(self))
    return null