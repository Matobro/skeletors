@tool
extends VBoxContainer

var plugin

@onready var name_input = $NameInput
@onready var sprite_input = $SpritePath
@onready var is_hero = $IsHero
@onready var create_button = $CreateButton

var unit_path := "res://RTS-System/Entities/Units/"
var hero_path := "res://RTS-System/Entities/Heroes/"
var template_path := "res://RTS-System/Entities/Templates/"

func _ready():
    create_button.pressed.connect(_on_create_pressed)

func _on_create_pressed():
    var unit_name = name_input.text.strip_edges()
    if unit_name == "":
        push_error("Unit name is required!")
        return

    var isHero = is_hero.button_pressed
    var paths := _get_paths(unit_name, isHero)

    # Ensure directories
    _ensure_dir(paths.database)
    _ensure_dir(paths.data)

    # Create resources
    var unit_data := _create_unit_data(paths.data_template, unit_name)
    var model_data := _create_model_data(unit_name)
    var sprite_frames := _create_sprite_frames(unit_name)

    # Wire them up
    model_data.sprite_frames = sprite_frames
    unit_data.unit_model_data = model_data

    # Save resources
    ResourceSaver.save(unit_data, paths.database + unit_name + ".tres")
    ResourceSaver.save(model_data, paths.data + unit_name + "_modeldata.tres")
    ResourceSaver.save(sprite_frames, paths.data + unit_name + "_spriteframes.tres")

    print("Created new %s: %s" % ["hero" if isHero else "unit", unit_name])


func _get_paths(unit_name: String, isHero: bool) -> Dictionary:
    if isHero:
        return {
            "database": hero_path + "Database/",
            "data": hero_path + "UnitData/" + unit_name + "/",
            "data_template": template_path + "HeroDataTemplate.tres"
        }
    else:
        return {
            "database": unit_path + "Database/",
            "data": unit_path + "UnitData/" + unit_name + "/",
            "data_template": template_path + "UnitDataTemplate.tres"
        }


func _ensure_dir(path: String) -> void:
    var dir := DirAccess.open("res://")
    if not dir.dir_exists(path):
        dir.make_dir_recursive(path)


func _create_unit_data(template_path: String, unit_name: String) -> Resource:
    var unit_data := load(template_path).duplicate()
    unit_data.resource_name = unit_name
    unit_data.name = unit_name
    return unit_data


func _create_model_data(unit_name: String) -> Resource:
    var model_template := template_path + "UnitModelDataTemplate.tres"
    var model_data := load(model_template).duplicate()
    model_data.resource_name = unit_name + "_modeldata"
    return model_data

func _create_sprite_frames(unit_name: String) -> SpriteFrames:
    var sprite_frames := SpriteFrames.new()
    sprite_frames.resource_name = unit_name + "_spriteframes"

    if sprite_frames.has_animation("default"):
        sprite_frames.remove_animation("default")

    var animations := ["attack", "idle", "dying", "walk", "casting"]
    for anim in animations:
        sprite_frames.add_animation(anim)

    sprite_frames.set_animation_loop("attack", false)
    sprite_frames.set_animation_loop("dying", false)

    return sprite_frames