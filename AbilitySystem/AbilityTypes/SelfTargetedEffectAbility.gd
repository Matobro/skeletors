extends BaseAbilityType

class_name SelfTargetedEffectAbility

func cast(context: CastContext):
    var ability = context.ability.ability_data
    for effect in ability.effects:
        AbilitySystem.apply_effect(effect, context.caster, context.caster.global_position, context.caster)

func get_cast_label(_is_passive: bool) -> String:
    return "[SELF TARGETED]"
    
func is_valid_cast(context: CastContext) -> bool:
    for effect in context.ability.ability_data.effects:
        if effect.effect_type == "Damage":
            if effect.amount > context.caster.data.stats.current_health:
                return false
    return true