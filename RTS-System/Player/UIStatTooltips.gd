extends Node

class_name UIStatTooltips

var parent: PlayerUI
var ui_stats: UIUnitStats

func _init(parent_ref, ui_stats_ref) -> void:
	parent = parent_ref
	ui_stats = ui_stats_ref

func gather_stat_info(data, stat_name):
	var main_stat = ""
	if data.unit_type == "hero":
		main_stat = data.stats.main_stat
	match stat_name:
		"damage":
			var damage_range = StatModifiers.get_damage_range(data.stats.attack_damage, data.stats.attack_dice_roll)
			return str("Damage: %d - %d" % [damage_range[0], damage_range[1]], "\n",
			"\nAttacks per second : ", data.stats.attack_speed)
		"armor":
			return str("Armor: ", data.stats.armor, "\n",
			"\nDamage reduced by: ", int(StatModifiers.calculate_armor(data.stats.armor) * 100), "%\n",
			"\nMovement speed: ", data.stats.movement_speed)
		"str":
			if main_stat == "strength":
				return str("Strength: ", data.stats.strength, "\n",
				"\nEvery ", StatModifiers.main_stat_multiplier, " strength increases damage by 1. \n",
				"\nHealth is increased by ", StatModifiers.str_multiplier, " for every strength.\n",
				"\nHealth regeneration is increased by ", StatModifiers.regen_modifier, " for every strength.")
			else:
				return str("Strength: ", data.stats.strength, "\n",
				"\nHealth is increased by ", StatModifiers.str_multiplier, " for every strength.\n",
				"\nHealth regeneration is increased by ", StatModifiers.regen_modifier, " for every strength.")
		"agi":
			if main_stat == "agility":
				return str("Agility: ", data.stats.agility, "\n",
				"\nEvery ", StatModifiers.main_stat_multiplier, " agility increases damage by 1. \n",
				"\nAttack speed is increased by ", StatModifiers.agi_multiplier, " for every agility.\n",
				"\nEvery ", StatModifiers.armor_modifier, " agility increases armor by 1")
			else:	
				return str("Agility: ", data.stats.agility, "\n",
				"\nAttack speed is increased by ", StatModifiers.agi_multiplier, " for every agility. \n",
				"\nEvery ", StatModifiers.armor_modifier, " agility increases armor by 1") 
		"int":
			if main_stat == "intelligence":
				return str("Intelligence: ", data.stats.intelligence, "\n",
				"\nEvery ", StatModifiers.main_stat_multiplier, " intelligence increases damage by 1. \n",
				"\nMana is increased by ", StatModifiers.int_multiplier, " for every intelligence.\n",
				"\nMana regeneration is increased by ", StatModifiers.regen_modifier, " for every intelligence.")
			else:	
				return str("Intelligence: ", data.stats.intelligence, "\n",
				"\nMana is increased by ", StatModifiers.int_multiplier, " for every intelligence.\n",
				"\nMana regeneration is increased by ", StatModifiers.regen_modifier, " for every intelligence.")
		"xp_bar":
			return str("--------------------[" ,data.stats.xp, " / ", data.parent.get_xp_for_next_level(), "]--------------------")
		"hp_bar":
			return str("Health regeneration: ", data.stats.health_regen, "/s")
		"mp_bar":
			return str("Mana regeneration: ", data.stats.mana_regen, "/s")
		_:
			return ""

func _on_stat_hover_entered(stat_name):
	if parent.selected_unit != null:
		var label = ui_stats.stat_names[stat_name]
		var text = gather_stat_info(parent.selected_unit, stat_name)

		TooltipManager.show_tooltip(parent.player_id, text, label.global_position)
	
func _on_stat_hover_exited():
	TooltipManager.hide_tooltip(parent.player_id)