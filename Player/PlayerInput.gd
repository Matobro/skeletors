extends Node2D

@export var commands: CommandsData

var player_id = 1
var drag_start = Vector2.ZERO
var dragging = false
var attack_moving: bool = false

var selected_units: Array = []
var selectable_units: Array = []
const DRAG_THRESHOLD := 50.0

@onready var selection_box = $"../CanvasLayer/BoxSelection"
@onready var camera := get_viewport().get_camera_2d()

func _physics_process(delta):
	if selectable_units.size() > 0:
		for unit in selectable_units:
			if unit.dead:
				selectable_units.erase(unit)
	if selected_units.size() > 0:
		for unit in selected_units:
			if unit.dead:
				selected_units.erase(unit)
				
func _unhandled_input(event):
	var shift = Input.is_key_pressed(KEY_SHIFT)
	var pos = get_global_mouse_position()
	
	if event.is_action_pressed("a"):
		attack_moving = true
	if event.is_action_released("a"):
		attack_moving = false
		
	#Leftclick behaviour
	if event.is_action_pressed("mouse_left"):
		if attack_moving:
			if selected_units.size() > 0:
				for unit in selected_units:
					unit.issue_command("attack_move", pos, shift, player_id, null)
				dragging = false
				selection_box.visible = false
		else:
			drag_start = event.position
			select_unit_at_mouse_pos(pos, shift)
	
	#Leftclick released behaviour
	if event.is_action_released("mouse_left"):
		if dragging and !attack_moving: #Stop box select
			end_drag(event.position, shift)
			
	#Rightclick behaviour			
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			var click_target = check_click_hit(pos)
			if selected_units.size() > 0:
			#Issue move command to every valid selected unit
				for unit in selected_units:
					if unit.owner_id != player_id: continue
					#attack
					if click_target != null:
						if click_target.owner_id == 10:
							unit.issue_command("attack", click_target.position, shift, player_id, click_target)
						else:
							#follow
							unit.issue_command("follow", pos, shift, player_id, click_target)
					else:
						#move
						unit.issue_command("move", pos, shift, player_id, null)
				##Create move command visual at clicked position	- why is this here
				#if valid_units > 0:
					#var command_instance = commands.command_object.instantiate()
					#command_instance.position = pos
					#get_tree().current_scene.add_child(command_instance)
					#command_instance.init_node(commands.move_command, true)		
	
	#Mouse movement + leftclick behaviour	
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if attack_moving: return
		var distance = drag_start.distance_to(event.position)
		if distance > DRAG_THRESHOLD: #Only start drag if moving mouse slightly
			if !dragging:
				start_drag() #Start box select
			update_drag(event.position)

###Box select logic###
func start_drag():
	dragging = true
	selection_box.visible = true
	selection_box.global_position = drag_start
	selection_box.size = Vector2.ZERO
	
func update_drag(current_pos: Vector2):
	print("box select active")
	var top_left = Vector2(
		min(drag_start.x, current_pos.x),
		min(drag_start.y, current_pos.y)
	)
	var size = (current_pos - drag_start).abs()
	
	selection_box.global_position = top_left
	selection_box.size = size
	
func end_drag(mouse_pos: Vector2, shift):
	dragging = false
	selection_box.visible = false
	
	var drag_rect = Rect2(selection_box.global_position, selection_box.size)
	select_units_in_box(Rect2(selection_box.global_position, selection_box.size), shift)
	
func select_units_in_box(box: Rect2, shift):
	print("box selecting")
	if !shift:
		for unit in selected_units:
			unit.set_selected(false)
		selected_units.clear()
		
	for unit in selectable_units:
		if unit.owner_id != player_id: continue
		var screen_pos = camera.get_viewport_transform() * unit.global_position
		if box.has_point(screen_pos):
			if unit not in selected_units:
				selected_units.append(unit)
				unit.set_selected(true)
###Box select logic end###		

func check_click_hit(mouse_pos: Vector2):
	var space_state = get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = 30.0
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, mouse_pos)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query, 10)
	
	if results.size() > 0:
		var collider = results[0].collider
		if collider and collider.has_method("set_selected"):
			return collider
		return false
		
###Single select logic###
func select_unit_at_mouse_pos(mouse_pos: Vector2, shift):
	var result = check_click_hit(mouse_pos)
	if result:
		print("single selecting - target [", result,"]")
		if !shift:
			for unit in selected_units:
				unit.set_selected(false)
			
			selected_units.clear()
		
		result.set_selected(true)
		selected_units.append(result)
		
		#unselect all units if clicking ground, disabled for now cause it fucks up selecting multiple units
		#when you first select one and then add more with box select
	#elif result == null:
		#for unit in selected_units:
			#unit.set_selected(false)
		#selected_units.clear()
###Single select logic end###
