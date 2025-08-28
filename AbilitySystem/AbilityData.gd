extends Resource

class_name AbilityData

@export var name: String
@export var description: String
@export var icon: Texture2D

@export var mana_cost: int
@export var cooldown: float
@export var cast_range: float
@export var cast_time: float

@export_enum("TargetedProjectile", "GroundArea", "NoTarget", "Aura", "BuffAbility")
var spell_type: String = "TargetedProjectile"

@export var projectile_scene: PackedScene
@export var effects: Array[EffectData]