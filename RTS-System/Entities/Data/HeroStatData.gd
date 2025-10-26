extends BaseStatData

class_name HeroStatData

### Stats ###

@export_group("Hero Stats")
@export_enum("strength", "agility", "intelligence") var main_stat: String = ""
@export var strength: int
@export var agility: int
@export var intelligence: int

@export_group("Stat Gains")
@export var strength_per_level: int
@export var agility_per_level: int
@export var intelligence_per_level: int

@export_group("Level Info")
## Do not change
var level: int = 1
## Do not change
var xp: int
## Do not change
var xp_to_level: int = 500

func gain_stats(_str, _agi, _int):
	strength += _str
	agility += _agi
	intelligence += _int
	recalculate_stats()

func recalculate_stats():
	var stat_list = {
		"max_health": [base_max_health, get_bonus_health(), 0],
		"attack_speed": [base_attack_speed, get_bonus_attack_speed(), 0.01],
		"max_mana": [base_max_mana, get_bonus_mana(), 0],
		"armor": [base_armor, get_bonus_armor(), 0],
		"movement_speed": [base_movement_speed, get_bonus_movement_speed(), 50],
		"health_regen": [base_health_regen, get_bonus_health_regen(), 0],
		"mana_regen": [base_mana_regen, get_bonus_mana_regen(), 0],
		"attack_range": [base_attack_range, get_bonus_attack_range(), 30],
		"attack_damage": [base_attack_damage, get_bonus_attack_damage(), 1],
	}

	for stat_name in stat_list.keys():
		var stat_values = stat_list[stat_name] 
		var base_value = stat_values[0]
		var bonus_value = stat_values[1]
		var min_value = stat_values[2]
		var item_bonus = get_item_bonus(stat_name)
		var buff_value = buff_bonus.get(stat_name, 0)

		self[stat_name] = max(base_value + bonus_value + item_bonus + buff_value, min_value)

	parent.unit_visual.hp_bar.hp_bar_set_new_values(current_health, max_health)
	
func get_bonus_health() -> int:
	if strength * StatModifiers.str_multiplier <= 0:
		return 0

	return strength * StatModifiers.str_multiplier

func get_bonus_attack_speed() -> float:
	if agility * StatModifiers.agi_multiplier <= 0:
		return 0.0

	return agility * StatModifiers.agi_multiplier
	
func get_bonus_mana() -> int:
	if intelligence * StatModifiers.int_multiplier <= 0:
		return 0

	return intelligence * StatModifiers.int_multiplier

func get_bonus_health_regen() -> float:
	if strength * StatModifiers.regen_modifier <= 0:
		return 0.0

	return strength * StatModifiers.regen_modifier

func get_bonus_mana_regen() -> float:
	if intelligence * StatModifiers.regen_modifier <= 0:
		return 0.0

	return intelligence * StatModifiers.regen_modifier

func get_bonus_armor() -> int:
	if agility / StatModifiers.armor_modifier < 1:
		return 0

	return agility / StatModifiers.armor_modifier

func get_item_bonus(stat_name: String) -> float:
	if parent.unit_inventory:
		return parent.unit_inventory.get_item_bonus(stat_name)
	return 0

### TO DO ###

func get_bonus_movement_speed() -> int:
	return 0

func get_bonus_attack_range() -> int:
	return 0

### END OF TODO ###

func get_bonus_attack_damage() -> int:
	match main_stat:
		"strength":
			return max (1, int(floor(strength / StatModifiers.main_stat_multiplier)))
		"agility":
			return max (1, int(floor(agility / StatModifiers.main_stat_multiplier)))
		"intelligence":
			return max (1, int(floor(intelligence / StatModifiers.main_stat_multiplier)))
		_:
			return 0
		
