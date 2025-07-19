extends Node2D

@export var commands: CommandsData

var dev_disable_input: bool = false

var player_id = null
var drag_start = Vector2.ZERO
var dragging = false
var attack_moving: bool = false
var is_local_player: bool

var block_input_frames: int = 0
var selected_units: Array = []
var selectable_units: Array = []
const DRAG_THRESHOLD := 50.0

@onready var selection_box = $"../CanvasLayer/BoxSelection"
@onready var player = get_parent()

var player_ui = null
var camera = null

func init_node() -> void:
	if !player.is_local_player:
		return
	
	player_id = player.player_id
	camera = player.player_camera
	player_ui = player.player_ui
	print(player_id)

func _physics_process(_delta):
	if !player.is_local_player:
		return

	if block_input_frames > 0:
		block_input_frames -= 1
		
	if selectable_units.size() > 0:
		for unit in selectable_units:
			if unit.dead:
				selectable_units.erase(unit)
	if selected_units.size() > 0:
		for unit in selected_units:
			if unit.dead:
				selected_units.erase(unit)

func _unhandled_input(event):
	if !player.is_local_player:
		return

	if dev_disable_input:
		return

	if get_viewport().gui_get_hovered_control() != null:
		dragging = false
		selection_box.visible = false
		selection_box.size = Vector2.ZERO
		return
		
	if block_input_frames > 0:
		dragging = false
		selection_box.visible = false
		selection_box.size = Vector2.ZERO
		return

	var shift = Input.is_key_pressed(KEY_SHIFT)
	var pos = get_global_mouse_position()
	var click_target = check_click_hit(pos)
	var total_units := selected_units.size()
	
	if event.is_action_pressed("a"):
		attack_moving = true
	if event.is_action_released("a"):
		attack_moving = false
	if event.is_action_pressed("s"):
		for unit in selected_units:
			unit.issue_command("stop", pos, shift, player_id, null)
	if event.is_action_pressed("h"):
		for unit in selected_units:
			unit.issue_command("hold", pos, shift, player_id, null)
		
	#Leftclick behaviour
	if event.is_action_pressed("mouse_left"):
		if attack_moving:
			if total_units == 0: return
			
			#calculate formation in which units arrive at target so they dont clump up
			var formation_targets = calculate_unit_formation(total_units, pos)
			
			#issue commands to units with altered end position based on formation
			for i in range(total_units):
				var unit = selected_units[i]
				var target_pos = formation_targets[i]
				if target_pos == null: continue
				
				unit.issue_command("attack_move", target_pos, shift, player_id, null)
				
			dragging = false
			selection_box.visible = false
		else:
			drag_start = event.position
			select_unit_at_mouse_pos(pos, shift)
	
	#Leftclick released behaviour
	if event.is_action_released("mouse_left"):
		if dragging and !attack_moving: #Stop box select
			end_drag(shift)
			
	#Rightclick behaviour			
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			#return if no units selected
			if total_units == 0: return
			
			#calculate formation in which units arrive at target so they dont clump up
			var formation_targets = calculate_unit_formation(total_units, pos)
			
			#issue commands to units with altered end position based on formation
			for i in range(total_units):
				var unit = selected_units[i]
				var target_pos = formation_targets[i]
				if target_pos == null: continue
				
				handle_commands(unit, target_pos, shift, click_target)

	
	#Mouse movement + leftclick behaviour	
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if attack_moving: return
		var distance = drag_start.distance_to(event.position)
		if distance > DRAG_THRESHOLD: #Only start drag if moving mouse slightly
			if !dragging:
				start_drag() #Start box select
			update_drag(event.position)

func handle_commands(unit, pos, shift, click_target):
	if unit.owner_id == player_id:
		#attack
		if click_target != null:
			if click_target.owner_id == 10:
				unit.issue_command("attack", pos, shift, player_id, click_target)
			else:
				#follow
				unit.issue_command("follow", pos, shift, player_id, click_target)
		else:
			#move
			unit.issue_command("move", pos, shift, player_id, null)
				
func calculate_unit_formation(total_units, pos):
	var unit_targets := []
	var spacing := 82.0
	var columns = int(ceil(sqrt(total_units)))
	var rows := int(ceil(total_units / float(columns)))
	
	var total_width = (columns - 1) * spacing
	var total_height = (rows - 1) * spacing
	
	for i in range(total_units):
		var row = float(i) / columns
		var column: int = i % columns
		
		var offset := Vector2(
			column * spacing - total_width / 2,
			row * spacing - total_height / 2
		)
		
		offset += Vector2(randf_range(-20, 20), randf_range(-20, 20))
		unit_targets.append(pos + offset)
	
	return unit_targets
		
			#final_target = pos + offset
###Box select logic###
func start_drag():
	dragging = true
	selection_box.visible = true
	selection_box.global_position = drag_start
	selection_box.size = Vector2.ZERO
	
func update_drag(current_pos: Vector2):
	var top_left = Vector2(
		min(drag_start.x, current_pos.x),
		min(drag_start.y, current_pos.y)
	)
	var size = (current_pos - drag_start).abs()
	
	selection_box.global_position = top_left
	selection_box.size = size
	
func end_drag(shift):
	dragging = false
	selection_box.visible = false
	
	select_units_in_box(Rect2(selection_box.global_position, selection_box.size), shift)
	
	if selected_units.size() > 0:
		for unit in selected_units:
			if unit.owner_id != player_id: continue
			
func select_units_in_box(box: Rect2, shift):
	if !shift:
		for unit in selected_units:
			unit.set_selected(false)
		selected_units.clear()
		player_ui.clear_control_group()
		
	for unit in selectable_units:
		if unit.owner_id != player_id: continue
		var screen_pos = camera.get_viewport_transform() * unit.global_position
		### if hits unit
		if box.has_point(screen_pos):
			### if hits and not already selected
			if unit not in selected_units:
				player_ui.add_unit_to_control(unit)
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
		if !shift:
			for unit in selected_units:
				unit.set_selected(false)
			selected_units.clear()
			player_ui.clear_control_group()
	
		result.set_selected(true)
		selected_units.append(result)
		player_ui.add_unit_to_control(result)
	#elif result == null:
		#player_ui.show_stats(false)
		#for unit in selected_units:
			#unit.set_selected(false)
		#selected_units.clear()
		#player_ui.clear_control_group()
###Single select logic end###

func _on_unit_died(unit):
	if unit in selectable_units:
		selectable_units.erase(unit)
		player_ui.remove_unit_from_group(unit)
