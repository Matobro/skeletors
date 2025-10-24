extends BaseAbilityType

class_name ChainAbility

@export var projectile: PackedScene
@export var jumps: int
@export var jump_delay: float
@export var jump_range: float

func cast(context: CastContext):
	var current_target = context.target_unit
	var previous_target = context.caster
	var targets_hit = []

	for i in range(jumps):
		if !is_instance_valid(current_target):
			break

		spawn_beam(previous_target.global_position, current_target.global_position, context.caster)

		for effect in context.ability.ability_data.effects:
			AbilitySystem.apply_effect(effect, context.caster, current_target.global_position, current_target)

		await context.caster.get_tree().create_timer(jump_delay).timeout

		targets_hit.append(current_target)
		var units_in_range = await get_units_in_range(current_target.global_position, jump_range, context.caster)
		var next_target = get_next_target(units_in_range, targets_hit, context)

		if !next_target:
			return

		previous_target = current_target
		current_target = next_target

func spawn_beam(start_pos, end_pos, caster):
	var beam = projectile.instantiate()
	caster.get_tree().current_scene.add_child((beam))
	beam.setup(start_pos, end_pos)

func get_units_in_range(center: Vector2, radius: float, caster) -> Array:
	var area = Area2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	var collision = CollisionShape2D.new()
	collision.shape = shape
	area.add_child(collision)
	caster.get_tree().current_scene.add_child(area)
	area.global_position = center
	area.monitoring = true
	area.collision_layer = 3
	area.collision_mask = 1 << 0
	await caster.get_tree().physics_frame
	await caster.get_tree().physics_frame
	
	var results := []
	for body in area.get_overlapping_bodies():
		results.append(body)
	area.queue_free()
	return results

func get_next_target(possible_targets, excluded_targets, context):
	for unit in possible_targets:
		if unit not in excluded_targets and is_valid_unit(unit) and context.caster.owner_id != unit.owner_id:
			return unit
	return false

func is_valid_unit(unit) -> bool:
	if !is_instance_valid(unit) or unit == null or !unit.unit_combat or unit.unit_combat.dead:
		return false
	return true

func get_cast_label(_is_passive: bool) -> String:
	return "[TARGETED]"
	
func is_valid_cast(context: CastContext) -> bool:
	if !is_valid_unit(context.target_unit):
		return false
	return true
