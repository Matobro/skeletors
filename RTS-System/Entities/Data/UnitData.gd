extends Resource

class_name UnitData

@export var power_level: int = 0
@export var is_spawnable_enemy: bool = false
@export var unit_model_data: UnitModelData
@export var unit_library: AnimationLibrary
@export var unit_type: String
@export var name: String
@export var description: String
@export var avatar: SpriteFrames
@export var stats: BaseStatData

var parent = null
var hero: Hero = null

func get_unit_type() -> String:
	return unit_type
