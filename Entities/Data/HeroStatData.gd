extends BaseStatData

class_name HeroStatData

### Stats ###
@export_enum("strength", "agility", "intelligence") var main_stat: String = ""

@export var strength: int
@export var agility: int
@export var intelligence: int
@export var level: int
@export var xp: int
@export var xp_to_level: int

### Multipliers ###
var str_multiplier: int = 2
var agi_multiplier: float = 0.01
var int_multiplier: int = 2

func get_bonus_health() -> int:
    return strength * str_multiplier

func get_bonus_attack_speed() -> float:
    return agility * agi_multiplier
    
func get_bonus_mana() -> int:
    return intelligence * int_multiplier

func get_bonus_attack_damage() -> int:
    match main_stat:
        "strength":
            return max (1, int(floor(strength / 3)))
        "agility":
            return max (1, int(floor(strength / 3)))
        "intelligence":
            return max (1, int(floor(strength / 3)))
        _:
            return 0
            