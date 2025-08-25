extends Node

class_name SelectionManager

var selected_units = []

var last_clicked_unit = null

var parent: PlayerInput
var player_ui
var player_id

signal selection_changed(selected_units: Array[Unit])

func _init(parent_ref, player_ui_ref, player_id_ref) -> void:
	parent = parent_ref
	player_ui = player_ui_ref
	player_id = player_id_ref

func update_selection():
	emit_signal("selection_changed", selected_units)

func select_unit(unit: Unit):
	if unit not in selected_units:
		selected_units.append(unit)
		unit.unit_visual.set_selected(true)
		update_selection()

func deselect_unit(unit: Unit):
	if unit in selected_units:
		selected_units.erase(unit)
		unit.unit_visual.set_selected(false)
		update_selection()

func clear_selection():
	if selected_units.size() > 0:
		for unit in selected_units.duplicate():
			unit.unit_visual.set_selected(false)
			selected_units.erase(unit)
	update_selection()

func get_first_selected_unit() -> Unit:
	return selected_units[0] if selected_units.size () > 0 else null
	
func cleanup_invalid_units():
	for unit in selected_units:
		if unit == null or unit.unit_combat.dead:
			deselect_unit(unit)

func apply_selection(units: Array, shift: bool) -> void:
	if !shift:
		for u in selected_units.duplicate():
			deselect_unit(u)

	if shift and selected_units.size() > 0:
		var owner_id = selected_units[0].owner_id
		units = units.filter(func(u): return u.owner_id == owner_id)

	for u in units:
		if u not in selected_units:
			select_unit(u)  # handles emit/visuals
			
func select_unit_at_mouse_pos(mouse_pos: Vector2, shift: bool) -> void:
	var clicked_unit = parent.check_click_hit(mouse_pos)
	print(clicked_unit)
	if clicked_unit == null:
		print("clicked nothing")
		clear_selection()
		return

	print("Clicked: ", clicked_unit)
	if !shift and clicked_unit in selected_units:
		# Clicking a selected unit without shift just reaffirms selection
		return

	if shift and selected_units.size() > 0:
		var current_owner = selected_units[0].owner_id
		if clicked_unit.owner_id != current_owner:
			return # ignore foreign units when shift-selecting

		if clicked_unit in selected_units:
			deselect_unit(clicked_unit)
			return

	apply_selection([clicked_unit], shift)

func select_units_in_box(box: Rect2, shift: bool) -> void:
	var units_in_box: Array = []
	var own_units_in_box: Array = []
	var enemy_units_in_box: Array = []

	# Collect all units in box
	for unit in UnitHandler.all_units:
		var screen_pos = parent.world_to_screen(unit.global_position)
		if box.has_point(screen_pos):
			units_in_box.append(unit)
			if unit.owner_id == player_id:
				own_units_in_box.append(unit)
			else:
				enemy_units_in_box.append(unit)

	# Nothing selected
	if units_in_box.is_empty():
		if !shift:
			clear_selection()
		return

	# Determine the owner we should select
	var current_owner_id: int = -1
	if selected_units.size() > 0:
		current_owner_id = selected_units[0].owner_id

	var new_selection: Array = []

	if current_owner_id == -1:
		# No current selection: prefer own units if any
		new_selection = own_units_in_box if own_units_in_box.size() > 0 else enemy_units_in_box
	else:
		# Filter box units to only match current owner
		new_selection = units_in_box.filter(func(u): return u.owner_id == current_owner_id)

	if shift:
		if new_selection.size() == 0:
			return  # nothing to toggle

		# Determine if there is any *new* unit not selected
		var has_new_unit = false
		for unit in new_selection:
			if unit not in selected_units:
				has_new_unit = true
				break

		if has_new_unit:
			# Add all new units of same owner
			for unit in new_selection:
				if unit not in selected_units:
					select_unit(unit)
		else:
			# All units already selected → deselect them
			for unit in new_selection:
				deselect_unit(unit)
	else:
		# Normal selection (replace)
		apply_selection(new_selection, false)

func select_all_units_of_type(unit: Unit) -> void:
	var candidates: Array = []
	for other_unit in UnitHandler.all_units:
		if other_unit.owner_id == unit.owner_id and other_unit.data.name == unit.data.name:
			candidates.append(other_unit)

	apply_selection(candidates, false)
