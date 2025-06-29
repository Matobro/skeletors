extends Resource

class_name UnitData

@export var name: String
@export var description: String
@export var avatar: Texture2D
@export var stats: Dictionary = {
	"strength": 1, 
	"agility": 1, 
	"intelligence": 1, 
	"max_health": 1,
	"current_health": 1,
	"max_mana": 1, 
	"armor": 1,
	"movement_speed": 1, 
	"health_regen": 0.1, 
	"mana_regen": 0.1, 
	"attack_speed": 1.0, 
	"base_damage": 1,
	"range": 1
	}
