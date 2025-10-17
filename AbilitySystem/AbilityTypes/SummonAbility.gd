extends BaseAbilityType

class_name SummonAbility

@export var summoned_unit: UnitData
@export var units_summoned: int

func cast(context: CastContext):
    for i in units_summoned:
        UnitSpawner.spawn_unit(summoned_unit, context.target_position, context.caster.owner_id)
        context.target_position.y += 100

func get_cast_label(_is_passive: bool) -> String:
    return "[SUMMON]"
    
func is_valid_cast(_context: CastContext) -> bool:
    return true