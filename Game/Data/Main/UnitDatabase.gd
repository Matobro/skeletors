extends Node

var hero_list: Array[UnitData] = []
var unit_list: Array[UnitData] = []

func _ready() -> void:
	load_unit_data()

func load_unit_data():
	load_units_from_manifest("res://RTS-System/data_manifest.json")

func load_units_from_manifest(manifest_path: String) -> void:
	var file = FileAccess.open(manifest_path, FileAccess.READ)
	if not file:
		push_error("Cannot open manifest file: " + manifest_path)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("Failed to parse manifest JSON: " + json.get_error_message())
		return
	
	var manifest = json.get_data()
	
	hero_list.clear()
	unit_list.clear()
	
	# Load heroes
	if manifest.has("heroes"):
		for path in manifest["heroes"]:
			var unit = ResourceLoader.load(path)
			if unit and unit is UnitData:
				print("Loaded: ", unit.name)
				hero_list.append(unit)
			else:
				print("Failed to load hero: ", path)
	
	# Load units
	if manifest.has("units"):
		for path in manifest["units"]:
			var unit = ResourceLoader.load(path)
			if unit and unit is UnitData:
				print("Loaded: ", unit.name)
				unit_list.append(unit)
			else:
				print("Failed to load unit: ", path)

func get_enemy_units_for_wave(wave: int) -> Array[UnitData]:
	var enemies = unit_list.filter(func(u): return u.power_level <= wave and u.is_spawnable_enemy)
	return enemies
