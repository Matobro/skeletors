extends Area2D

@export var speed: float = 400
var target: Node2D
var effects: Array[EffectData] = []

var source_ability
var caster

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_collision"))
	
func _physics_process(delta: float) -> void:
	if !target or !is_instance_valid(target):
		free_self()

	print("Target: ", target)
	var direction = (target.global_position - global_position).normalized()
	global_position += direction * speed * delta

func _on_collision(body):
	print("Hit: ", body)
	if body == target:
		for effect in effects:
			source_ability.apply_effect(effect, caster, Vector2.ZERO, target)
		free_self()
		
func free_self():
	queue_free()
