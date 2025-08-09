extends Ability

class_name GroundTargetedAbility

const GroundTargetedAbilityInstance = preload("res://RTS-System/Abilities/Dummies/GroundTargetedAbility.tscn")

@export var is_wave: bool
@export var area_radius: float
@export var move_speed: int
@export var damage: int
@export var lifetime: float

func activate_ability(position: Vector2, world_node: Node, caster_owner: Node) -> Node:
	print("casting ability at: ", position)
	var instance = GroundTargetedAbilityInstance.instantiate()
	instance.setup(self, position, world_node, caster_owner)
	return instance
