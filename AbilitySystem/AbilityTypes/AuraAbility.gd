extends BaseAbilityType

class_name AuraAbility
@export var aura_radius: float = 400.0

func cast(context: CastContext):
    var aura_area = AuraArea.new()
    aura_area.source_unit = context.caster
    aura_area.ability = context.ability
    aura_area.aura_radius = aura_radius
    context.caster.add_child(aura_area)

func get_cast_label(_is_passive: bool) -> String:
    return "[AURA]"
    
func is_valid_cast(_context: CastContext) -> bool:
    return true