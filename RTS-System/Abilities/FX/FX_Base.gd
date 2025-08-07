extends Node2D

@export var fx_texture: Texture2D
@export var fx_color: Gradient
@export var fx_scale: float = 1.0
@export var fx_duration: float = 1.0
@export var auto_free: bool = true

func _ready() -> void:
	var particles := $GPUParticles2D
	var mat = particles.process_material as ParticleProcessMaterial

	if fx_texture:
		particles.texture = fx_texture
	if fx_color:
		mat.color_ramp = fx_color
	
	mat.scale = Vector2(fx_scale, fx_scale)
	particles.lifetime = fx_duration
	particles.emitting = true

	if auto_free:
		await get_tree().create_timer(fx_duration).timeout
		queue_free()
