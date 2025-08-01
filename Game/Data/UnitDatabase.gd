extends Node

var hero_list: Array = []
var unit_list: Array = []

func _ready() -> void:
	load_unit_data()

func load_unit_data():
	hero_list = load_units_from_folder("res://Entities/Heroes/Heroes/", "hero")
	unit_list = load_units_from_folder("res://Entities/Units/Units/", "unit")

func load_units_from_folder(folder_path: String, unit_type: String) -> Array:
	var dir = DirAccess.open(folder_path)
	var units: Array = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".tres"):
				var unit_path = folder_path + "/" + file_name
				var _unit = load(unit_path)
				if _unit and _unit is UnitData and _unit.unit_type == unit_type:
					units.append(_unit)
			file_name = dir.get_next()
		dir.list_dir_end()
	return units

func get_enemy_units_for_wave(wave: int) -> Array:
	var enemies = unit_list.filter(func(u): return u.power_level <= wave and u.is_spawnable_enemy)
	return enemies