extends Ability

class_name AoeRainAbility

const AoeRainAbilityInstance = preload("res://RTS-System/Abilities/Logic/AoeRainAbilityInstance.gd")
const AreaIndicator = preload("res://RTS-System/Abilities/Data/AreaIndicator.tscn")

@export var wave_count: int
@export var duration: float
@export var damage_per_wave: int
@export var area_radius: float

func get_targets_in_area(position: Vector2, radius: float, world_node: Node):
	var space_state = world_node.get_world_2d().direct_space_state

	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius

	var transform = Transform2D.IDENTITY
	transform.origin = position

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = circle_shape
	query.transform = transform
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var results = space_state.intersect_shape(query, 32)

	var targets = []
	for hit in results:
		var collider = hit.collider
		if collider and collider.is_in_group("unit"):
			targets.append(collider)
		
	return targets

func activate_ability(position: Vector2, world_node: Node, caster_owner: Node) -> Node:
	print("casting ability at: ", position)
	var instance = AoeRainAbilityInstance.new()
	instance.setup(self, position, world_node, caster_owner)
	return instance
