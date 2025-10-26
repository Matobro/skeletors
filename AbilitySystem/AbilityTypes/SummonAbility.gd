extends BaseAbilityType

class_name SummonAbility

@export var summoned_unit: UnitData
@export var units_summoned: int
@export var duration: float

## Stat scaling for ability
@export_category("Scaling")
## Scaling per stat point. eg max_health 0.01 = +1% max hp per intelligence. ex: 500 base hp + 7 int = 535 hp
@export var summon_stat_scaling: Dictionary = {
	"intelligence": {
		"max_health": 0.0,
		"attack_damage": 0.0,
		"summon_count": 0.0
	},
}

func cast(context: CastContext):
	var caster = context.caster
	var scaling_data = get_spell_scaling(context.ability)

	var total_summons = get_units_summoned(context.ability) + units_summoned

	for i in range(total_summons):
		var summon = summon_unit(context)
		_apply_scaled_stats(summon, scaling_data)

# Summon specific functions
func summon_unit(context) -> Unit:
	var summon = UnitSpawner.spawn_unit(summoned_unit, context.target_position, context.caster.owner_id)
	return summon

func get_units_summoned(ability: BaseAbility):
	var caster = ability.parent
	var extra_summons = 0
	for stat_name in summon_stat_scaling.keys():
		var stat_value = caster.data.stats.get(stat_name)
		var count_factor = summon_stat_scaling[stat_name].get("summon_count", 0.0)
		extra_summons += int(stat_value * count_factor)
	
	return extra_summons

func _apply_scaled_stats(summon, scaling_data: Dictionary):
	var summon_stats: BaseStatData = summon.data.stats
	for stat_name in scaling_data.keys():
		var scaled = scaling_data[stat_name]
		var difference = scaled["scaled"] - scaled["base"]
		summon_stats.buff_bonus[stat_name] = summon_stats.buff_bonus.get(stat_name, 0.0) + difference

	summon_stats.recalculate_stats()
	summon_stats.current_health = summon_stats.max_health
	summon_stats.current_mana = summon_stats.max_mana
#---------------------------#

func is_valid_cast(_context: CastContext) -> bool:
	return true

func get_cast_label(_is_passive: bool) -> String:
	return "[GROUND TARGETED]"

func get_scaling_values(_ability: BaseAbility) -> Dictionary:
	return {
		"max_health": summoned_unit.stats.base_max_health,
		"attack_damage": summoned_unit.stats.base_attack_damage,
		"summon_count": units_summoned
	}

func get_scaling_map() -> Dictionary:
	return summon_stat_scaling

func get_tooltip(ability: BaseAbility) -> String:
	var scaling_data = get_spell_scaling(ability)
	var summon_data = summoned_unit

	var txt = "[font_size=14]Summon: [color=red]%s[/color]\n" % summon_data.name
	txt += "Duration: [color=yellow]%ds[/color]\n" % int(duration)
	
	var base_summons = units_summoned
	var bonus = get_units_summoned(ability)
	var total = bonus + base_summons
	var _source_stat = "N/A"

	if scaling_data.has("summon_count"):
		var summon_info = scaling_data["summon_count"]
		_source_stat = summon_info["source_stat"].capitalize()

	txt += "Summons: [color=yellow]%d[/color]" % total
	txt += " [font_size=10][color=green](+%d from %s)[/color][/font_size]\n" % [
		bonus,
		_source_stat
	]

	txt += "[/font_size]"

	# Summon stats
	txt += "\n\n[font_size=14]Summon Stats:\n"

	# Hp + damage
	if scaling_data.has("max_health"):
		var hp_info = scaling_data["max_health"]
		var difference = hp_info["scaled"] - hp_info["base"]
		txt += "Health: [color=yellow]%d[/color] [font_size=10][color=green](+%d from %s)[/color][/font_size]\n" % [
			hp_info["scaled"],
			difference,
			hp_info["source_stat"].capitalize()
		]
	else:
		txt += "Health: [color=yellow]%d[/color]\n" % summon_data.stats.base_max_hp

	if scaling_data.has("attack_damage"):
		var dmg_info = scaling_data["attack_damage"]
		var difference = dmg_info["scaled"] - dmg_info["base"]
		txt += "Damage: [color=yellow]%d[/color] [font_size=10][color=green](+%d from %s)[/color][/font_size]\n" % [
			dmg_info["scaled"],
			difference,
			dmg_info["source_stat"].capitalize()
		]
	else:
		txt += "Damage: [color=yellow]%d[/color]\n" % summon_data.stats.base_attack_damage

	txt += "[/font_size]"

	# Scaling data
	if !summon_stat_scaling.is_empty():
		txt += "\n[font_size=10][color=gray]Scaling:\n"
		for source_stat in summon_stat_scaling.keys():
			for affected_stat in summon_stat_scaling[source_stat].keys():
				var factor = summon_stat_scaling[source_stat][affected_stat]
				if factor <= 0:
					continue

				if affected_stat == "summon_count":
					var per_value = 1.0 / factor
					txt += "+1 Summon per %d %s\n" % [per_value, source_stat.capitalize()]
				else:
					txt += "+%.1f%% %s per %s\n" % [
						factor * 100.0,
						affected_stat.capitalize(),
						source_stat.capitalize()
					]
		txt += "[/color][/font_size]"

	return txt
