# Logic for Fireball ability

extends Area2D

## Speed of the projectile
@export var speed: float = 400

## Target of this spell
var target: Node2D
## Spell effects - damage, stun, slow etc
var effects: Array[EffectData] = []

## Unit that casted this ability
var caster

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_collision"))
	
func _physics_process(delta: float) -> void:
	if !target or !is_instance_valid(target):
		free_self()

	var direction = (target.global_position - global_position).normalized()
	global_position += direction * speed * delta

func _on_collision(body):
	if body == target:
		for effect in effects:
			AbilitySystem.apply_effect(effect, caster, Vector2.ZERO, target)
		free_self()
		
func free_self():
	queue_free()
