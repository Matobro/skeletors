extends Node

var fx_map: Dictionary = {}

func _ready() -> void:
	var dir := DirAccess.open("res://RTS-System/Abilities/FX/FXResources/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var path = "res://RTS-System/Abilities/FX/FXResources/" + file_name
				var fx_res = ResourceLoader.load(path)
				if fx_res is FXResource:
					fx_map[file_name.get_basename()] = fx_res
			file_name = dir.get_next()

func play_fx(fx_res: FXResource, position: Vector2, _scale, _radius):
	if !fx_res: return

	var fx = fx_res.fx_scene.instantiate()
	fx.position = position
	fx.fx_texture = fx_res.texture
	fx.fx_color = fx_res.color
	fx.fx_scale = _scale
	fx.fx_radius = _radius
	fx.fx_duration = fx_res.duration
	get_tree().current_scene.add_child(fx)

func attach_and_play_fx(fx_res: FXResource, position: Vector2, _scale, _radius, lifetime, dir, origin):
	if !fx_res: return

	var fx = fx_res.fx_scene.instantiate()
	fx.fx_texture = fx_res.texture
	fx.fx_scale = _scale
	fx.fx_radius = _radius
	fx.fx_duration = lifetime
	fx.will_follow = true
	fx.follow_target = origin
	fx.dir = dir
	get_tree().current_scene.add_child(fx)
	fx.global_position = position
