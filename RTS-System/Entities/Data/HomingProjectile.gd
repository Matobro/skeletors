extends Node2D

var target
var speed = 300
var damage = 0
var owner_unit
var homing = true

func _process(delta):
	if target == null or !is_instance_valid(target):
		print("invalid target")
		queue_free()
		return
	
	var dir = (target.global_position - global_position).normalized()
	rotation = dir.angle()
	
	position += dir * speed * delta
	if global_position.distance_to(target.global_position) <= 6:
		target.unit_combat.take_damage(damage, owner_unit)
		queue_free()
