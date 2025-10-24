extends Node

var data_manifest: Dictionary;
var units: Array[UnitData]
var heroes: Array[UnitData]

func _ready() -> void:
	load_manifest("res://RTS-System/data_manifest.json")
	units = _get_units()
	heroes = _get_heroes()

	if units.size() > 0 and heroes.size() > 0:
		print("Unit database successfully loaded with: [%d] heroes and [%d] units" % [heroes.size(), units.size()])
		GameManager.on_unit_database_loaded()

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

## Returns all [UnitData] for heroes
func get_hero_list() -> Array[UnitData]:
	return heroes

## Returns all [UnitData] for units
func get_unit_list() -> Array[UnitData]:
	return units

func _get_heroes() -> Array[UnitData]:
	var heroes: Array[UnitData] = [];

	if data_manifest.has("heroes"):
		for path in data_manifest["heroes"]:
			var unit = ResourceLoader.load(path)
			if unit and unit is UnitData:
				#print("Loaded: Hero - ", unit.name)
				heroes.append(unit)
			else:
				print("Failed to load hero: ", path)

	if heroes.is_empty():
		push_error("No heroes found in database")
		return []

	return heroes

func _get_units() -> Array[UnitData]:
	var units: Array[UnitData] = [];

	if data_manifest.has("units"):
		for path in data_manifest["units"]:
			var unit = ResourceLoader.load(path)
			if unit and unit is UnitData:
				#print("Loaded: Unit - ", unit.name)
				units.append(unit)
			else:
				print("Failed to load unit: ", path)
	if units.is_empty():
		push_error("No units found in database")
		return []
	return units
