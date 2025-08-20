@tool
extends EditorPlugin

var button

var count_code := 0
var count_comments := 0
var count_total := 0

func _enter_tree():
    button = Button.new()
    button.text = "Count Lines"
    button.connect("pressed", Callable(self, "_on_button_pressed"))
    add_control_to_container(CONTAINER_TOOLBAR, button)
    print("Line Counter plugin loaded")

func _exit_tree():
    remove_control_from_container(CONTAINER_TOOLBAR, button)
    button.free()
    print("Line Counter plugin unloaded")

func _on_button_pressed():
    count_code = 0
    count_comments = 0
    count_total = 0

    count_dir("res://")

    print("Total lines: ", count_total, "\nReal lines: ", count_code, "\nComments: ", count_comments)

func count_dir(path: String):
    var dir = DirAccess.open(path)
    if not dir:
        return

    # Iterate directories
    for d in dir.get_directories():
        if d in ["addons", ".import"]:
            continue
        count_dir(path + "/" + d)

    # Iterate files
    for f in dir.get_files():
        if f.get_extension() != "gd":
            continue
        var file = FileAccess.open(path + "/" + f, FileAccess.READ)
        if not file:
            continue
        var lines = file.get_as_text().split("\n")
        for line in lines:
            count_total += 1
            if line.strip_edges().begins_with("#"):
                count_comments += 1
            elif line.strip_edges() != "":
                count_code += 1
