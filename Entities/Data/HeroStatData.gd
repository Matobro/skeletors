extends BaseStatData

class_name HeroStatData

### Stats ###
@export var strength: int
@export var agility: int
@export var intelligence: int

### Multipliers ###
var str_multiplier: int
var agi_multiplier: int
var int_multiplier: int

func get_bonus_health() -> int:
    return strength * str_multiplier

func get_bonus_attack_speed() -> float:
    return agility * agi_multiplier
    
func get_bonus_mana() -> int:
    return intelligence * int_multiplier