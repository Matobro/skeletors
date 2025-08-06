extends Resource

class_name BaseStatData

### Stats ##
@export_category("Stats")
@export_group("Base Stats")
@export var base_max_hp: int = 5
@export var base_max_mana: int = 0
@export var base_health_regen: float = 0.1
@export var base_mana_regen: float = 0.1
@export var base_armor: int = 1
@export var base_movement_speed: int = 330
@export var base_attack_speed: float = 1.0
@export var base_damage: int = 2
@export var base_range: int = 50
@export var attack_dice_roll: int = 2
@export var xp_yield: int = 50

# @export_group("Current Stats")
var max_health: int = 0
var max_mana: int = 0
var armor: int = 0
var movement_speed: int = 0
var health_regen: float = 0.0
var mana_regen: float = 0.0
var attack_speed: float = 0.0
var attack_range: int = 0

var current_health: int
var current_mana: int
var attack_damage: int

func recalculate_stats():
	var previous_max_hp = max_health
	var previous_max_mana = max_mana

	max_health = base_max_hp
	attack_speed = base_attack_speed
	max_mana = base_max_mana
	armor = base_armor
	movement_speed = base_movement_speed
	health_regen = base_health_regen
	mana_regen = base_mana_regen
	attack_range = base_range
	attack_damage = base_damage

	if previous_max_hp > 0:
		current_health = int(current_health * max_health / previous_max_hp)
	else:
		current_health = max_health

	if previous_max_mana > 0:
		current_mana = int(current_mana * max_mana / previous_max_mana)
	else:
		current_mana = max_mana