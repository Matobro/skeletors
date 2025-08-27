extends Node

var SPELL_TYPE = {
	"TargetedProjectile": preload("res://AbilitySystem/AbilityTypes/TargetedProjectile.gd")
}

func create_ability(ability_data: AbilityData) -> BaseAbility:
	var ability = BaseAbility.new()
	ability.ability_data = ability_data
	ability.ability_type = get_ability_type(ability_data.spell_type)
	return ability
	
func get_ability_type(spell_type: String) -> BaseAbilityType:
	if SPELL_TYPE.has(spell_type):
		return SPELL_TYPE[spell_type].new()
	
	print("Returning null")
	return null
	
func apply_effect(effect: EffectData, caster, target_position: Vector2, target_unit = null):
	match effect.effect_type:
		"Damage":
			if target_unit:
				target_unit.unit_combat.take_damage(effect.amount)
		"Heal":
			if target_unit:
				target_unit.unit_combat.heal_health(effect.amount)
		"Buff":
			if target_unit:
				target_unit.unit_combat.add_buff(effect)
		"Debuff":
			if target_unit:
				target_unit.unit_combat.add_debuff(effect)
		"Stun":
			if target_unit:
				target_unit.unit_combat.get_stunned(effect.duration)
		"Slow":
			if target_unit:
				target_unit.unit_combat.apply_slow(effect.amount, effect.duration)
		"Summon":
			pass
			#_spawn_summon(effect, caster, target_position)
		"Custom":
			if effect.extra.has("callback"):
				var cb = effect.extra["callback"]
				if cb is Callable:
					cb.call(caster, target_unit, target_position)
