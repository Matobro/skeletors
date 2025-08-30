extends Node
class_name SelectionManager

var selected_units: Array = []
var last_clicked_unit = null

var parent: PlayerInput
var player_ui
var player_id

signal selection_changed(selected_units: Array[Unit])

func _init(parent_ref, player_ui_ref, player_id_ref) -> void:
	parent = parent_ref
	player_ui = player_ui_ref
	player_id = player_id_ref

func update_selection(old_selection: Array) -> void:
	if old_selection != selected_units:
		emit_signal("selection_changed", selected_units)

func _select_unit(unit: Unit) -> void:
	if unit not in selected_units:
		selected_units.append(unit)
		unit.unit_visual.set_selected(true)

func _deselect_unit(unit: Unit) -> void:
	if unit in selected_units:
		selected_units.erase(unit)
		unit.unit_visual.set_selected(false)

func clear_selection() -> void:
	var old_selection = selected_units.duplicate()
	for unit in selected_units.duplicate():
		unit.unit_visual.set_selected(false)
	selected_units.clear()
	update_selection(old_selection)

func apply_selection(units: Array, shift: bool) -> void:
	var old_selection = selected_units.duplicate()
	var new_selection: Array

	if shift:
		new_selection = selected_units.duplicate()
		for u in units:
			if u in new_selection:
				new_selection.erase(u)
			else:
				new_selection.append(u)
	else:
		new_selection = units.duplicate()

	for u in selected_units:
		if u not in new_selection and is_valid_unit(u):
			u.unit_visual.set_selected(false)
	for u in new_selection:
		if u not in selected_units and is_valid_unit(u):
			u.unit_visual.set_selected(true)

	selected_units = new_selection
	update_selection(old_selection)

func select_unit_at_mouse_pos(mouse_pos: Vector2, shift: bool) -> void:
	var clicked_unit = parent.check_click_hit(mouse_pos)
	if clicked_unit == null:
		clear_selection()
		return

	if shift and selected_units.size() > 0:
		var current_owner = selected_units[0].owner_id
		if clicked_unit.owner_id != current_owner:
			return

	apply_selection([clicked_unit], shift if selected_units.size() > 0 else false)

func select_units_in_box(box: Rect2, shift: bool) -> void:
	var units_in_box: Array = []
	for unit in UnitHandler.all_units:
		var screen_pos = parent.world_to_screen(unit.global_position)
		if box.has_point(screen_pos) and is_valid_unit(unit):
			if unit.owner_id == player_id:
				units_in_box.append(unit)

	if units_in_box.is_empty():
		if !shift:
			apply_selection([], false)
		return

	apply_selection(units_in_box, shift)

func select_all_units_of_type(unit: Unit, shift := false) -> void:
	var candidates: Array = []
	for other_unit in UnitHandler.all_units:
		if is_valid_unit(other_unit) and is_valid_unit(unit) and other_unit.owner_id == unit.owner_id and other_unit.data.name == unit.data.name:
			candidates.append(other_unit)

	if shift:
		var new_selection = selected_units.duplicate()
		for u in candidates:
			if u not in new_selection and is_valid_unit(u):
				new_selection.append(u)
		apply_selection(new_selection, false)
	else:
		apply_selection(candidates, false)

func get_first_selected_unit() -> Unit:
	return selected_units[0] if selected_units.size() > 0  and selected_units[0] != null else null

func cleanup_invalid_units():
	var changed = false
	for unit in selected_units.duplicate():
		if unit == null or unit.unit_combat.dead:
			_deselect_unit(unit)
			changed = true
	if changed:
		apply_selection(selected_units.duplicate(), false)

func is_valid_unit(unit: Unit) -> bool:
	if unit and unit != null and is_instance_valid(unit) and unit.unit_combat and !unit.unit_combat.dead:
		return true
	return false

func is_valid_selection() -> bool:
	return selected_units.size() > 0 and is_instance_valid(selected_units[0])
