extends Area2D

class_name AuraArea

var source_unit: Unit
var ability: BaseAbility
var aura_radius: float = 0.0
var affected_units := {}
var refresh_timer := 0.0

var caster_effect

const REFRESH_INTERVAL := 1.0

func _ready() -> void:
	var shape = CircleShape2D.new()
	shape.radius = aura_radius

	var collision = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

	monitoring = true
	monitorable = false
	collision_layer = 3
	collision_mask = 1 << 0

	var effect_sprite = AnimatedSprite2D.new()
	effect_sprite.sprite_frames = caster_effect
	add_child(effect_sprite)
	effect_sprite.play("default")
	effect_sprite.scale = source_unit.data.unit_model_data.scale
	effect_sprite.global_position = Vector2(source_unit.global_position.x, source_unit.global_position.y)

	connect("body_entered", Callable(self, "on_body_entered"))
	connect("body_exited", Callable(self, "on_body_exited"))

func _process(delta: float) -> void:
	refresh_timer -= delta
	if refresh_timer <= 0:
		refresh_timer = REFRESH_INTERVAL
		for body in affected_units.keys():
			if !is_instance_valid(body): continue
			for effect in ability.ability_data.effects:
				AbilitySystem.apply_effect(effect, source_unit, body.global_position, body)

func on_body_entered(body):
	print("entered")
	if !body.is_in_group("unit"):
		return
	
	for effect in ability.ability_data.effects:
		AbilitySystem.apply_effect(effect, source_unit, body.global_position, body)
	
	affected_units[body] = ability.ability_data.effects

func on_body_exited(body):
	if affected_units.has(body):
		affected_units.erase(body)
