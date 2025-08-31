extends Resource

class_name AbilityData

@export var name: String
@export var description: String
@export var icon: Texture2D

@export var mana_cost: int
@export var cooldown: float
@export var cast_range: float
@export var cast_time: float
@export var is_passive: bool

@export_enum("TargetedProjectile", "GroundArea", "NoTarget", "Aura", "BuffAbility")
var spell_type: String = "TargetedProjectile"

enum Target {
    ENEMY = 1 << 0,
    FRIENDLY = 1 << 1,
    SELF = 1 << 2,
}

@export_flags("Enemy", "Friendly", "Self")
var possible_targets: int = 0

@export var projectile_scene: PackedScene
@export var effects: Array[EffectData]

## Returns true if targeted unit type [Enemy, Friendly, Self] is in this ability [possible_targets]
func is_valid_target(caster, target) -> bool:
    if !target or !caster:
        return false
    
    # Self
    if (possible_targets & Target.SELF) != 0 and target == caster:
        print("Casting on self")
        return true
    
    # Enemy
    if (possible_targets & Target.ENEMY) != 0 and target.owner_id == 10:
        print("Casting on enemy")
        return true
    
    # Friendly
    if (possible_targets & Target.FRIENDLY) != 0 and target.owner_id != 10 and target != caster:
        print("Casting on friendly target")
        return true

    print("Not a valid ability target.")
    return false

func get_info_text() -> String:
    var text = str(
        "Right click to cast ", name
    )
    return text
