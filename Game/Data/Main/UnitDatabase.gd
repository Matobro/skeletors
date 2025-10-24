extends Node

enum UnitType {
	HERO,
	UNIT,
	NEUTRAL
}

var data_manifest: Dictionary;

func _ready() -> void:
	load_manifest("res://RTS-System/data_manifest.json")
	
func load_manifest(manifest_path: String) -> void:
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

	data_manifest = json.get_data()


func get_hero_data() -> Array[UnitData]:
	var heroes: Array[UnitData] = [];

	if data_manifest.has("heroes"):
		for path in data_manifest["heroes"]:
			var unit = ResourceLoader.load(path)
			if unit and unit is UnitData:
				heroes.append(unit)
			else:
				print("Failed to load hero: ", path)

	if heroes.is_empty():
		push_error("No heroes found in database")
		return []

	return heroes

func get_unit_data() -> Array[UnitData]:
	var units: Array[UnitData] = [];

	if data_manifest.has("units"):
		for path in data_manifest["units"]:
			var unit = ResourceLoader.load(path)
			if unit and unit is UnitData:
				units.append(unit)
			else:
				print("Failed to load unit: ", path)
	if units.is_empty():
		push_error("No units found in database")
		return []
	return units
