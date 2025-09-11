## Base for TargetedAbilities
## Is casted on target unit
## Instantiates projectile that holds its own logic
## Is valid cast is unique for each ability type
## For example, targetedprojectile should check
## that the targeted unit is valid
## and not the target position

extends BaseAbilityType

class_name TargetedProjectile

@export var projectile_scene: PackedScene

func cast(context: CastContext):
	var projectile = projectile_scene.instantiate()
	projectile.global_position = context.caster.global_position
	projectile.target = context.target_unit
	projectile.effects = context.ability.ability_data.effects.duplicate()
	projectile.caster = context.caster
	context.caster.get_tree().current_scene.add_child(projectile)

func get_cast_label(_is_passive: bool) -> String:
	return "[TARGETED]"

func is_valid_cast(context: CastContext) -> bool:
	# Check spell specific rules
	if !(context.caster or 
	context.ability or 
	projectile_scene or 
	context.target_unit or 
	context.target_unit.unit_combat or 
	!context.target_unit.unit_combat.dead): \
	return false
	
	return context.ability.ability_data.is_valid_target(context.caster, context.target_unit)
