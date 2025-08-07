extends Node2D

@export var fx_texture: Texture2D
@export var fx_color: Gradient
@export var fx_scale: float = 1.0
@export var fx_duration: float = 1.0
@export var fx_radius: float = 1.0
@export var auto_free: bool = true

func _ready() -> void:
	var particles := $GPUParticles2D
	var fx_material = particles.process_material as ParticleProcessMaterial

	if fx_texture:
		particles.texture = fx_texture
	
	fx_material.scale = Vector2(fx_scale, fx_scale)
	fx_material.emission_sphere_radius = fx_radius
	particles.lifetime = fx_duration
	particles.emitting = true

	deletus()

func deletus():
	if auto_free:
		await get_tree().create_timer(fx_duration).timeout
		queue_free()
