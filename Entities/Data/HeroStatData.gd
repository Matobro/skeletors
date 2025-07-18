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
@export var level: int
@export var xp: int
@export var xp_to_level: int = 500


### Multipliers ###
var str_multiplier: int = 2
var agi_multiplier: float = 0.01
var int_multiplier: int = 2

func gain_stats(_str, _agi, _int):
	strength += _str
	agility += _agi
	intelligence += _int
	recalculate_stats()

func recalculate_stats():
	var previous_max_hp = max_health
	var previous_max_mana = max_mana

	max_health = base_max_hp + get_bonus_health()
	attack_speed = base_attack_speed + get_bonus_attack_speed()
	max_mana = base_max_mana + get_bonus_mana()
	armor = base_armor + get_bonus_armor()
	movement_speed = base_movement_speed + get_bonus_movement_speed()
	health_regen = base_health_regen + get_bonus_health_regen()
	mana_regen = base_mana_regen + get_bonus_mana_regen()
	attack_range = base_range + get_bonus_attack_range()
	attack_damage = base_damage + get_bonus_attack_damage()

	if previous_max_hp > 0:
		current_health = int(current_health * max_health / previous_max_hp)
	else:
		current_health = max_health

	if previous_max_mana > 0:
		current_mana = int(current_mana * max_mana / previous_max_mana)
	else:
		current_mana = max_mana


func get_bonus_health() -> int:
	return strength * str_multiplier

func get_bonus_attack_speed() -> float:
	return agility * agi_multiplier
	
func get_bonus_mana() -> int:
	return intelligence * int_multiplier

### TO DO ###
func get_bonus_armor() -> int:
	return 0

func get_bonus_movement_speed() -> int:
	return 0

func get_bonus_health_regen() -> float:
	return 0.0

func get_bonus_mana_regen() -> float:
	return 0.0

func get_bonus_attack_range() -> int:
	return 0

### END OF TODO ###

func get_bonus_attack_damage() -> int:
	match main_stat:
		"strength":
			return max (1, int(floor(strength / 3)))
		"agility":
			return max (1, int(floor(agility / 3)))
		"intelligence":
			return max (1, int(floor(intelligence / 3)))
		_:
			return 0
			