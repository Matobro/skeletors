extends BaseAbilityType

class_name SummonAbility

@export var summoned_unit: UnitData
@export var units_summoned: int
@export var duration: float

func cast(context: CastContext):
	AbilitySystem.apply_effect(context.ability.ability_data.effects[0], context.caster, context.target_position, null, context.ability)

func get_cast_label(_is_passive: bool) -> String:
	return "[SUMMON]"
	
func is_valid_cast(_context: CastContext) -> bool:
	return true
