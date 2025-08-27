## Base for TargetedAbilities
## Is casted on target unit
## Instantiates projectile that holds its own logic

extends BaseAbilityType

func cast(context: CastContext):	
	var projectile = context.ability_data.projectile_scene.instantiate()
	projectile.global_position = context.caster.global_position
	projectile.target = context.target_unit
	projectile.effects = context.ability_data.effects.duplicate()
	projectile.caster = context.caster
	context.caster.get_tree().current_scene.add_child(projectile)

func is_valid_cast(context: CastContext) -> bool:
	if context.caster and context.ability_data and context.ability_data.projectile_scene and context.target_unit and context.target_unit.unit_combat and !context.target_unit.unit_combat.dead:
		return true
	return false