extends Area2D

@onready var collider = $CollisionShape2D
var ability_config: GroundTargetedAbility
var world_node : Node
var _owner: Node

var is_wave: bool
var area_radius: float
var move_speed: int
var damage: int
var lifetime: float
var radius: float

var dir: Vector2
var is_setup_done: int = 0
var lifetime_timer: Timer

func _ready() -> void:
	collider.shape.radius = radius
	is_setup_done += 1

func setup(config: GroundTargetedAbility, pos: Vector2, world: Node, owner_node: Node):

	### Get ability info

	ability_config = config
	world_node = world
	_owner = owner_node
	radius = config.area_radius

	### Get stats from ability config

	is_wave = config.is_wave
	area_radius = config.area_radius
	move_speed = config.move_speed
	damage = config.damage
	lifetime = config.lifetime
	
	### Setup position

	position = owner_node.global_position
	dir = (pos - owner_node.global_position).normalized()

	### Play FX
	var _scale = radius / 32
	var _radius = radius * 3
	ParticleManager.attach_and_play_fx(ability_config.fx, position, _scale, _radius, lifetime, dir, self)

	### Setup timers

	lifetime_timer = Timer.new()
	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	ParticleManager.add_child(lifetime_timer)

	lifetime_timer.timeout.connect(_on_timer_timeout)
	lifetime_timer.start()

	is_setup_done += 1

func _physics_process(delta: float) -> void:
	if is_setup_done < 2:
		return

	position += dir * move_speed * delta


func _on_timer_timeout():
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.owner_id == 10:
		body.unit_combat.take_damage(damage)
