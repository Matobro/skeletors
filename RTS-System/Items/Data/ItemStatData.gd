extends Resource

class_name ItemStatData

### Stats ##
@export_category("Stats")
@export_group("Stats")
@export var max_health: float = 0
@export var max_mana: float = 0
@export var armor: int = 0
@export var movement_speed: int = 0
@export var health_regen: float = 0.0
@export var mana_regen: float = 0.0
@export var attack_speed: float = 0.0
@export var attack_range: int = 0
@export var current_health: float = 0.0
@export var current_mana: float = 0.0
@export var attack_damage: float = 0.0

func get_stats_dictionary() -> Dictionary:
    var stat_dictionary = {}
    for prop in get_property_list():
        if prop.name in ["resource_name", "resource_path"]:
            continue
        var value = get(prop.name)
        if typeof(value) in [TYPE_FLOAT, TYPE_INT]:
            if value != 0:
                stat_dictionary[prop.name] = value
    return stat_dictionary