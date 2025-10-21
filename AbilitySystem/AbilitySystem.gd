extends Node

func create_ability(ability_data: AbilityData, source_unit) -> BaseAbility:
	var ability = BaseAbility.new(ability_data, source_unit)
	return ability
## Applies [effect] originating from [caster] to [target_unit]
func apply_effect(effect: EffectData, caster, target_position: Vector2, target_unit = null, ability = null):

	match effect.effect_type:
		"Damage":
			if target_unit:
				target_unit.unit_combat.take_damage(effect.amount)
		"Heal":
			if target_unit:
				target_unit.unit_combat.heal_health(effect.amount)
		"Buff":
			if target_unit:
				target_unit.unit_combat.add_buff(effect, caster)
		"Debuff":
			if target_unit:
				target_unit.unit_combat.add_buff(effect, caster)
		"Stun":
			if target_unit:
				target_unit.unit_combat.get_stunned(effect.duration)
		"Slow":
			if target_unit:
				target_unit.unit_combat.apply_slow(effect.amount, effect.duration)
		"Summon":
			if caster:
				var data = ability.ability_data
				var type = data.ability_type
				caster.unit_combat.summon_unit(type.units_summoned, type.duration, type.summoned_unit, target_position, caster.owner_id)
		"Heal_Mana":
			if target_unit:
				target_unit.unit_combat.heal_mana(effect.amount)
		"Custom":
			if effect.extra.has("callback"):
				var cb = effect.extra["callback"]
				if cb is Callable:
					cb.call(caster, target_unit, target_position)
