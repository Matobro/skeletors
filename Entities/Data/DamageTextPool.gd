extends Node

class_name DamageTextPool

var damage_text = preload("res://Entities/Data/DamageText.tscn")
var pool := []

func show_text(text: String, pos: Vector2):
	var instance = null
	for label in pool:
		if !label.visible:
			instance = label
			break
			
	if instance == null:
		instance = damage_text.instantiate()
		pool.append(instance)
		add_child(instance)
		
	instance.text = text
	instance.global_position = Vector2(pos.x -10, pos.y - 25)
	instance.show()
	instance.timer = 0.0
