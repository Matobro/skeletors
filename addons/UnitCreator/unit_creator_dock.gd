@tool
extends VBoxContainer

var plugin

@onready var name_input = $NameInput
@onready var sprite_input = $SpritePath
@onready var create_button = $CreateButton

func _ready():
    create_button.pressed.connect(_on_create_pressed)

func _on_create_pressed():
    var unit_name = name_input.text.strip_edges()
    if unit_name == "":
        push_error("Unit name is required!")
        return
    
    var base_path = "res://RTS-System/Entities/Units/"
    var database_path = base_path + "Database/"
    var data_path = base_path + "UnitData/" + unit_name + "/"

    # Ensure directories
    var dir = DirAccess.open("res://")
    if not dir.dir_exists(database_path):
        dir.make_dir_recursive(database_path)
    if not dir.dir_exists(data_path):
        dir.make_dir_recursive(data_path)

    # Create resources
    var unit_data = load(base_path + "Templates/" + "UnitDataTemplate.tres").duplicate()
    unit_data.resource_name = unit_name

    unit_data.name = unit_name

    var model_data = load(base_path + "Templates/" + "UnitModelDataTemplate.tres").duplicate()
    model_data.resource_name = unit_name + "_modeldata"

    var sprite_frames = SpriteFrames.new()
    sprite_frames.resource_name = unit_name + "_spriteframes"

    if sprite_frames.has_animation("default"):
        sprite_frames.remove_animation("default")

    var default_animations = ["attack", "idle", "dying", "walk"]
    for anim in default_animations:
        sprite_frames.add_animation(anim)

    sprite_frames.set_animation_loop("attack", true)
    sprite_frames.set_animation_loop("idle", true)
    sprite_frames.set_animation_loop("walk", true)
    sprite_frames.set_animation_loop("dying", false)

    # Wire them up
    model_data.sprite_frames = sprite_frames
    unit_data.unit_model_data = model_data

    # Save resources
    ResourceSaver.save(unit_data, database_path + unit_name + ".tres")
    ResourceSaver.save(model_data, data_path + unit_name + "_modeldata.tres")
    ResourceSaver.save(sprite_frames, data_path + unit_name + "_spriteframes.tres")

    print("Created new unit: ", unit_name)
