extends Node2D

const CAMERA_BORDER_SIZE = 20
var edge_scroll_speed: int = 1000
var min_zoom := 0.5
var max_zoom := 2.0
var zoom_speed := 0.1
var zoom_duration := 0.2
var paused: bool = false
var camera_zoom := 1.0: set = set_camera_zoom
var controls_enabled: bool = true

@onready var pause_screen = $"../CanvasLayer/PlayerUI/PauseScreen"
@onready var camera: Camera2D = $"../PlayerCamera"

func _ready():
	set_camera_zoom(camera_zoom)
	
func _process(delta):
	if controls_enabled:
		var mouse_pos = get_viewport().get_mouse_position()
		var screen_size = get_viewport_rect().size
		
		if(mouse_pos.x <= CAMERA_BORDER_SIZE):
			camera.position.x -= edge_scroll_speed * delta
		elif(mouse_pos.x >= screen_size.x - CAMERA_BORDER_SIZE):
			camera.position.x += edge_scroll_speed * delta
		
		if(mouse_pos.y <= CAMERA_BORDER_SIZE):
			camera.position.y -= edge_scroll_speed * delta
		elif(mouse_pos.y >= screen_size.y - CAMERA_BORDER_SIZE):
			camera.position.y += edge_scroll_speed * delta

func _unhandled_input(event):
	if event.is_action_pressed("esc"):
			paused = !paused
			pause_screen.visible = paused
			controls_enabled = !paused
			get_tree().paused = paused
	if controls_enabled:
		if event.is_action_pressed("scroll_up"):
			set_camera_zoom(camera_zoom + zoom_speed)
		if event.is_action_pressed("scroll_down"):
			set_camera_zoom(camera_zoom - zoom_speed)
		
func set_camera_zoom(value: float) -> void:
	camera_zoom = clamp(value, min_zoom, max_zoom)
	camera.zoom = Vector2(camera_zoom, camera_zoom)
	
func set_camera_controls(value):
	controls_enabled = value
