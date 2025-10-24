extends Node

var items: Dictionary = {}

func _ready() -> void:
	load_item_data()

func load_item_data():
	load_items_from_manifest("res://RTS-System/data_manifest.json")

func load_items_from_manifest(manifest_path: String) -> void:
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
	
	items.clear()
	
	# Load items
	if manifest.has("items"):
		for path in manifest["items"]:
			var item = ResourceLoader.load(path)
			if item and item is ItemData:
				#print("Loaded: ", item.name, " (", item.id, ")")
				items[item.id] = item
			else:
				print("Failed to load item: ", path)