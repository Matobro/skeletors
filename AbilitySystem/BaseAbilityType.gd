## Overridden in each ability type

extends Resource

class_name BaseAbilityType

# Overridden in each ability type
func cast(_context: CastContext):
	pass

func get_cast_label(_is_passive: bool) -> String:
	return "[ABILITY]"

func get_tooltip(_ability: BaseAbility) -> String:
	return "[i] No tooltip data [/i]"

func get_scaling_values(_ability: BaseAbility) -> Dictionary:
	return {}

func get_scaling_map() -> Dictionary:
	return {}
#-------------------------------------------#

func get_spell_scaling(ability: BaseAbility) -> Dictionary:
	var caster = ability.parent
	if not caster:
		return {}

	var caster_stats = caster.data.stats
	var result := {}

	var base_values = ability.ability_data.ability_type.get_scaling_values(ability)
	var scaling_map = ability.ability_data.ability_type.get_scaling_map()

	for caster_stat in scaling_map.keys():
		var stat_value = caster_stats.get(caster_stat)
		var affected: Dictionary = scaling_map[caster_stat]

		for effect_key in affected.keys():
			var factor = affected[effect_key]
			var base_value = base_values.get(effect_key, 0)
			var scaled_value = base_value + base_value * (factor * stat_value)

			result[effect_key] = {
				"base": base_value,
				"scaled": scaled_value,
				"scale_factor": factor,
				"source_stat": caster_stat,
				"source_value": stat_value
			}

	print("Caster stats:", caster_stats)
	print("Scaling dict keys:", result.keys())
	return result
