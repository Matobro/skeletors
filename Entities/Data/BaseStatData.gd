extends Resource

class_name BaseStatData

### Stats ##
@export var max_health: int = 5
@export var max_mana: int = 0
@export var armor: int = 1
@export var movement_speed: int = 330
@export var health_regen: float = 0.1
@export var mana_regen: float = 0.1
@export var attack_speed: float = 1.0
@export var base_damage: int = 2
@export var attack_dice_roll: int = 2
@export var attack_range: int = 50

### 'Current' Values ###
@export var current_health: int
@export var current_mana: int
@export var attack_damage: int