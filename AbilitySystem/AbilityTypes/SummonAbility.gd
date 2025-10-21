extends BaseAbilityType

class_name SummonAbility

@export var summoned_unit: UnitData
@export var units_summoned: int
@export var duration: float

func cast(context: CastContext):
	for i in units_summoned:
		var summon = UnitSpawner.spawn_unit(summoned_unit, context.target_position, context.caster.owner_id)
		context.target_position.y += 100

		summon.data.is_summon = true
		summon.data.lifetime = duration

func get_cast_label(_is_passive: bool) -> String:
	return "[SUMMON]"
	
func is_valid_cast(_context: CastContext) -> bool:
	return true
