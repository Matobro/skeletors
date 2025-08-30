## Base for TargetedAbilities
## Is casted on target unit
## Instantiates projectile that holds its own logic

extends BaseAbilityType

func cast(context: CastContext):
	var projectile = context.ability.ability_data.projectile_scene.instantiate()
	projectile.global_position = context.caster.global_position
	projectile.target = context.target_unit
	projectile.effects = context.ability.ability_data.effects.duplicate()
	projectile.caster = context.caster
	context.caster.get_tree().current_scene.add_child(projectile)

func is_valid_cast(context: CastContext) -> bool:
	# Check spell specific rules
	if !(context.caster or 
	context.ability or 
	context.ability.ability_data.projectile_scene or 
	context.target_unit or 
	context.target_unit.unit_combat or 
	!context.target_unit.unit_combat.dead): \
	return false
	
	return context.ability.ability_data.is_valid_target(context.caster, context.target_unit)
