extends BaseAbilityType

class_name SelfTargetedEffectAbility

## Stat scaling for ability
@export_category("Scaling")
## Scaling per stat point
@export var scaling: Dictionary = {
	"intelligence": {
	},
}

func cast(context: CastContext):
	var ability = context.ability
	var scaling_data = get_spell_scaling(ability)

	for effect in ability.ability_data.effects:
		# not sure if this is good idea but probably yes
		var effect_instance = effect.duplicate()
		
		var key = "Buff_" + effect_instance.stat if effect_instance.stat != "" else effect_instance.effect_type
		if scaling_data.has(key):
			effect_instance.amount = scaling_data[key]["scaled"]
			
		AbilitySystem.apply_effect(effect_instance, context.caster, context.caster.global_position, context.caster)

func get_cast_label(_is_passive: bool) -> String:
	return "[SELF TARGETED]"

func get_scaling_values(ability: BaseAbility) -> Dictionary:
	var ability_data = ability.ability_data
	var values := {}
	for effect in ability_data.effects:
		var key = effect.stat if effect.stat != "" else effect.effect_type
		values[key] = effect.amount
	return values

func get_scaling_map() -> Dictionary:
	return scaling

func get_tooltip(ability: BaseAbility) -> String:
	var txt = "[font_size=14]"
	var scaling_data = get_spell_scaling(ability)

	var good_effects := []
	var bad_effects := []

	for effect in ability.ability_data.effects:
		var key = "Buff_" + effect.stat if effect.stat != "" else effect.effect_type
		var scaled_amount = effect.amount
		var extra_text = ""
		var duration_text = ""

		# Apply scaling
		if scaling_data.has(key):
			scaled_amount = scaling_data[key]["scaled"]
			var diff = scaled_amount - scaling_data[key]["base"]
			extra_text = "[font_size=10] (+%s from %s)[/font_size]" % [
				diff,
				scaling_data[key]["source_stat"].capitalize()
			]

		if effect.duration > 0:
			duration_text = " for %0.1fs" % effect.duration

		var display_name = effect.stat.replace("_", " ").capitalize() if effect.stat != "" else effect.effect_type.replace("_", " ").capitalize()

		# Seperate to "good" and "bad" effects # todo (buffs might be good or bad, unless i actually implement debuffs lmaooo
		# heal_mana might be bad too, unless another effect is made for that like "damage_mana" or smth)
		match effect.effect_type:
			"Buff", "Heal", "Heal_Mana":
				good_effects.append("%s: [color=green]%s%s[/color]%s" % [
					display_name,
					scaled_amount,
					extra_text,
					duration_text
				])
			"Debuff", "Damage", "Stun", "Slow":
				bad_effects.append("%s: [color=red]%s%s[/color]%s" % [
					display_name,
					scaled_amount,
					extra_text,
					duration_text
				])
			_:
				# Neutral/custom effecs
				good_effects.append("%s: %s%s%s" % [
					display_name,
					scaled_amount,
					extra_text,
					duration_text
				])

	# Build tooltip
	for line in good_effects:
		txt += line + "\n"
	for line in bad_effects:
		txt += line + "\n"

	txt += "[/font_size]"
	
	# Add scaling info
	if !scaling.is_empty():
		txt += "\n[font_size=10][color=gray]Scaling:\n"
		for source_stat in scaling.keys():
			for affected_key in scaling[source_stat].keys():
				var factor = scaling[source_stat][affected_key]
				if factor <= 0:
					continue

				txt += "+%.1f%% %s per %s\n" % [
					factor * 100.0,
					affected_key.replace("_", " ").capitalize(),
					source_stat.capitalize()
				]
		txt += "[/color][/font_size]"

	return txt

		
func is_valid_cast(context: CastContext) -> bool:
	for effect in context.ability.ability_data.effects:
		if effect.effect_type == "Damage":
			if effect.amount > context.caster.data.stats.current_health:
				return false
	return true