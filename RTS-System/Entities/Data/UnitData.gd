extends Resource

class_name UnitData

## 'Power level' for waves, higher = harder
@export var power_level: int = 0
## If it should be included in wave enemy pool
@export var is_spawnable_enemy: bool = false
## Used by summon abilities etc
var is_summon: bool = false
var lifetime: float = 10.0
## Unit 'model' data, such as sprite, animations, projectile
@export var unit_model_data: UnitModelData
@export var unit_type: UnitDatabase.UnitType
## Unit display name
@export var name: String
## Description, not implemented yet
@export var description: String
## This should just be the same spriteframes, as in model data. Been lazy
var avatar: SpriteFrames
## Unit stats, heroes use HeroStatData, units use BaseStatData
@export var stats: BaseStatData
## If unit uses ranged attacks
@export var is_ranged: bool

##Units abilities
@export var abilities: Array[AbilityData]
var parent = null
var hero: Hero = null

func get_stat(stat: String):
	return stats[stat]
