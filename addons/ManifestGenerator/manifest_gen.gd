@tool
extends EditorPlugin

var button

func _enter_tree():
    button = Button.new()
    button.text = "Generate Manifest"
    button.pressed.connect(_on_button_pressed)
    
    add_control_to_container(CONTAINER_TOOLBAR, button)

func _exit_tree():
    remove_control_from_container(CONTAINER_TOOLBAR, button)
    button.queue_free()

func _on_button_pressed():
    print("Manifest generation started")
    _generate_manifest()

func _generate_manifest():
    var scan_folders = {
        "heroes": "res://RTS-System/Entities/Heroes/Database",
        "units": "res://RTS-System/Entities/Units/Database",
        "items": "res://RTS-System/Items/Database"
    }
    var output_file_path = "res://RTS-System/data_manifest.json"

    var manifest_data = {
        "heroes": [],
        "units": [],
        "items": []
    }

    for category in scan_folders.keys():
        var folder_path = scan_folders[category]
        var dir = DirAccess.open(folder_path)
        if not dir:
            printerr("Failed to open folder: ", folder_path)
            continue
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if !dir.current_is_dir() and file_name.ends_with(".tres"):
                var full_path = folder_path + file_name if folder_path.ends_with("/") else folder_path + "/" + file_name
                manifest_data[category].append(full_path)
            file_name = dir.get_next()
        dir.list_dir_end()

    var json_text = JSON.stringify(manifest_data, "\t")
    var file = FileAccess.open(output_file_path, FileAccess.WRITE)
    if not file:
        printerr("Failed to open output file: ", output_file_path)
        return
    file.store_string(json_text)
    file.close()
    print("Manifest generated with HEROES [%d], UNITS [%d], ITEMS [%d] saved at [%s]"
        % [manifest_data["heroes"].size(), manifest_data["units"].size(), manifest_data["items"].size(), output_file_path])
