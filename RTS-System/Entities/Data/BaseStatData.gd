extends Resource

class_name BaseStatData

### Stats ##
@export_category("Stats")
@export_group("Base Stats")
## Units base hp, without any bonuses
@export var base_max_health: float = 5
## Units base mp, without any bonuses
@export var base_max_mana: float = 0
## Units base hp regen, without any bonuses
@export var base_health_regen: float = 0.1
## Units base mp regen, without any bonuses
@export var base_mana_regen: float = 0.1
## Units base armor, without any bonuses
@export var base_armor: int = 1
## Units base movement speed, without any bonuses
@export var base_movement_speed: int = 330
## Units base attack speed (attacks per second, higher = faster), without any bonuses
@export var base_attack_speed: float = 1.0
## Units base damage, without any bonuses
@export var base_attack_damage: int = 2
## Units base range, without any bonuses
@export var base_attack_range: int = 50
## Damage variance in percentage. 0.1 = 10%
## 100 damage + 0.1 dice roll = [90-110]
@export_range(0.0, 1.0) var attack_dice_roll: float = 0.1
## How much unit gives xp when killed
@export var xp_yield: int = 50

# @export_group("Current Stats")
var max_health: float = 0
var max_mana: float = 0
var armor: int = 0
var movement_speed: int = 0
var health_regen: float = 0.0
var mana_regen: float = 0.0
var attack_speed: float = 0.0
var attack_range: int = 0

var current_health: float
var current_mana: float
var attack_damage: int

var buff_bonus := {}

var parent

func recalculate_stats():
	var stat_list = {
		"max_health": [base_max_health, 0],
		"attack_speed": [base_attack_speed, 0.01],
		"max_mana": [base_max_mana, 0],
		"armor": [base_armor, 0],
		"movement_speed": [base_movement_speed, 50],
		"health_regen": [base_health_regen, 0],
		"mana_regen": [base_mana_regen, 0],
		"attack_range": [base_attack_range, 30],
		"attack_damage": [base_attack_damage, 1],
	}

	var hp_percent = 1.0
	if max_health > 0:
		hp_percent = current_health / max_health

	var mp_percent = 1.0
	if max_mana > 0:
		mp_percent = current_mana / max_mana

	for stat_name in stat_list.keys():
		var stat_values = stat_list[stat_name]
		var base_value = stat_values[0]
		var min_value = stat_values[1]
		var buff_value = buff_bonus.get(stat_name, 0)

		self[stat_name] = max(base_value + buff_value, min_value)

	current_health = max_health * hp_percent
	current_mana = max_mana * mp_percent

	parent.unit_visual.hp_bar.hp_bar_set_new_values(current_health, max_health)