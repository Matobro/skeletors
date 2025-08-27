@tool
extends EditorPlugin

var dock

func _enter_tree() -> void:
    var dock_scene = preload("res://addons/AbilityEditor/ability_editor_dock.tscn")
    dock = dock_scene.instantiate()
    dock.set_plugin(self)
    add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)

func _exit_tree() -> void:
    remove_control_from_docks(dock)
    dock.free()
