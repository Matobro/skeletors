extends AnimationPlayer

@export var anim_name: String = "default"
func _ready() -> void:
	play(anim_name)
