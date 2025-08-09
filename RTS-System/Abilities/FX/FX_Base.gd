extends Node2D

@export var fx_texture: Texture2D
@export var fx_color: Gradient
@export var fx_scale: float = 1.0
@export var fx_duration: float = 1.0
@export var fx_radius: float = 1.0
@export var will_follow: bool
@export var follow_target = null
@export var dir = null
@export var auto_free: bool = true
@export var particles: GPUParticles2D
func _ready() -> void:
	particles = $GPUParticles2D
	var fx_material = particles.process_material as ParticleProcessMaterial

	if fx_texture:
		particles.texture = fx_texture
	
	fx_material.scale_min = fx_scale
	fx_material.scale_max = fx_scale
	fx_material.emission_sphere_radius = fx_radius
	fx_material.initial_velocity_min = fx_radius
	fx_material.initial_velocity_max = fx_radius
	particles.lifetime = fx_duration
	particles.emitting = true

	if !will_follow:
		deletus()

func _process(_delta):
	if will_follow:
		if follow_target and is_instance_valid(follow_target):
			global_position = follow_target.global_position
			rotation = dir.angle() + deg_to_rad(90)
		else:
			particles.emitting = false
			deletus()

func deletus():
	if auto_free:
		await get_tree().create_timer(fx_duration).timeout
		queue_free()
