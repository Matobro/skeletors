extends Resource

class_name EffectData

@export_enum("Damage", "Heal", "Buff", "Debuff", "Stun", "Slow", "Summon", "Heal_Mana", "Custom")
var effect_type: String

@export var amount: float = 0
@export var duration: float = 0
@export var stat: String = ""
@export var extra: Dictionary = {}
@export var effect_sprite: SpriteFrames