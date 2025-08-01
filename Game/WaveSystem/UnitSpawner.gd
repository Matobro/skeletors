extends Node

var unit_scenes = {
	"hero": preload("res://Entities/Heroes/Data/Hero.tscn"),
	"unit": preload("res://Entities/Units/Data/Unit.tscn")
}

func spawn_enemy(unit_data: UnitData) -> Unit:
    var scene = unit_scenes["unit"] #<---- cant remember if this is the way to do it
    var unit = scene.instantiate()

    unit.data = unit_data
    unit.global_position = get_spawn_point()

    get_tree().current_scene.add_child(unit)
    return unit

func get_spawn_point() -> Vector2:
    return Vector2.ZERO