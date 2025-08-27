@tool
extends Control

@onready var ability_list = $VBoxContainer/AbilityList
@onready var add_button = $VBoxContainer/HBoxContainer/Add
@onready var duplicate_button = $VBoxContainer/HBoxContainer/Duplicate
@onready var delete_button = $VBoxContainer/HBoxContainer/Delete
@onready var rename_button = $VBoxContainer/HBoxContainer/Rename
@onready var rename_dialog = $VBoxContainer/RenameDialog
@onready var rename_line = $VBoxContainer/RenameDialog/LineEdit

var plugin: EditorPlugin = null
var abilities_dir := "res://AbilitySystem/Abilities/"
var selected_index := -1

func set_plugin(plugin_ref: EditorPlugin):
    plugin = plugin_ref

func _ready():
    add_button.pressed.connect(_on_add_pressed)
    duplicate_button.pressed.connect(_on_duplicate_pressed)
    delete_button.pressed.connect(_on_delete_pressed)
    rename_button.pressed.connect(_on_rename_pressed)
    ability_list.item_selected.connect(_on_ability_selected)
    rename_dialog.confirmed.connect(_on_rename_confirmed)
    _refresh_list()

func _refresh_list():
    ability_list.clear()
    var dir = DirAccess.open(abilities_dir)
    if dir:
        for file_name in dir.get_files():
            if file_name.ends_with(".tres"):
                ability_list.add_item(file_name)

func _on_add_pressed():
    var AbilityData = preload("res://AbilitySystem/AbilityData.gd")
    var ability = AbilityData.new()
    var path = abilities_dir + "NewAbility.tres"
    ResourceSaver.save(ability, path)
    _refresh_list()

func _on_duplicate_pressed():
    if ability_list.is_anything_selected():
        var name = ability_list.get_item_text(ability_list.get_selected_items()[0])
        var src_path = abilities_dir + name
        var res = ResourceLoader.load(src_path)
        var new_path = abilities_dir + "Copy_" + name
        ResourceSaver.save(res.duplicate(), new_path)
        _refresh_list()

func _on_rename_pressed():
    if ability_list.is_anything_selected():
        selected_index = ability_list.get_selected_items()[0]
        var old_name = ability_list.get_item_text(selected_index)
        rename_line.text = old_name.get_basename()
        rename_dialog.popup_centered()

func _on_delete_pressed():
    if ability_list.is_anything_selected():
        var name = ability_list.get_item_text(ability_list.get_selected_items()[0])
        DirAccess.remove_absolute(abilities_dir + name)
        _refresh_list()

func _on_ability_selected(index):
    var name = ability_list.get_item_text(index)
    var res = ResourceLoader.load(abilities_dir + name)
    if res and plugin:
        print("spell found")
        call_deferred("_inspect_resource_deferred", res)

func _inspect_resource_deferred(res):
    plugin.get_editor_interface().edit_resource(res)

func _on_rename_confirmed():
    if selected_index == -1:
        return

    var old_name = ability_list.get_item_text(selected_index)
    var new_name = rename_line.text.strip_edges()
    if new_name == "":
        return

    var old_path = abilities_dir + old_name
    var new_path = abilities_dir + new_name + ".tres"

    # Check if file exists
    if FileAccess.file_exists(new_path):
        print("Error: A file with that name already exists!")
        return

    # Rename using DirAccess instance
    var dir = DirAccess.open(abilities_dir)
    if dir:
        var err = dir.rename(old_name, new_name + ".tres")
        if err != OK:
            print("Failed to rename:", old_name, "to", new_path)
            return
    else:
        print("Error: Could not open abilities directory")
        return

    # Update AbilityData name property
    var res = ResourceLoader.load(new_path)
    if res:
        res.name = new_name
        ResourceSaver.save(res, new_path)

    # Refresh list and reselect
    _refresh_list()
    for i in range(ability_list.get_item_count()):
        if ability_list.get_item_text(i) == new_name + ".tres":
            ability_list.select(i)
            _on_ability_selected(i)
            break

