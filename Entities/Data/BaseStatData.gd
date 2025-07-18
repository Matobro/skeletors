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