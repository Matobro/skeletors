extends Node

class_name ActionMenuUI

const MANA_ICON_PATH = "res://AbilitySystem/Sprites/ManaIcon.png"
const COOLDOWN_ICON_PATH = "res://AbilitySystem/Sprites/CooldownIcon.png"
var player_id
var action_panel
var ability_grid
var player_ui: PlayerUI
var ability_slots = []

func _init(ui_ref):
	player_ui = ui_ref
	player_id = player_ui.player_object.player_id

func _ready():
	action_panel = $"../ActionMenu"
	ability_grid = $"../ActionMenu/AbilityButtons"

	if ability_grid:
		for i in range(ability_grid.get_child_count()):
			var slot = ability_grid.get_child(i)
			ability_slots.append(slot)
			slot.connect("mouse_entered", Callable(self, "on_mouse_hover").bind(slot))
			slot.connect("mouse_exited", Callable(self, "on_mouse_hover_exit"))
			slot.connect("gui_input", Callable(self, "on_ability_button_clicked").bind(i))

## Clears ui and then links selected unit abilities to ui slots
func update_action_menu(abilities: Array[BaseAbility] = []):
	clear_abilities()

	if abilities:
		for i in range(abilities.size()):
			ability_slots[i].set_slot(abilities[i], abilities[i].ability_data)

func clear_abilities():
	for slot in ability_slots:
		slot.set_slot(null, null)

func on_ability_button_clicked(event: InputEvent, index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player_input = player_ui.player_object.player_input
		var caster = player_input.selection_manager.get_first_selected_unit()
		if not caster:
			return
		
		# Create event info for casting
		var event_info = EventInfo.new()
		event_info.clicked_position = player_input.get_global_mouse_position()
		event_info.click_target = player_input.check_click_hit(event_info.clicked_position)
		event_info.click_item = player_input.check_click_hit_item(event_info.clicked_position)
		event_info.total_units = player_input.selection_manager.selected_units.size()
		event_info.shift = Input.is_action_pressed("shift")
		event_info.attack_moving = Input.is_action_pressed("a")

		# Start casting mode for this ability - also use is_button_cast flag to disable quick cast
		var keyhandler = player_input.keyboard_handler
		keyhandler.input_cast_spell(event_info, caster, index, true)

func on_mouse_hover(slot):
	var text = get_slot_text(slot)
	var pos = action_panel.global_position
	TooltipManager.show_tooltip(player_id, text, pos)

func on_mouse_hover_exit():
	TooltipManager.hide_tooltip(player_id)

func get_slot_text(slot) -> String:
	var ability = slot.ability
	var data = slot.data
	var spell_type = data.ability_type

	var parts := []

	# Name and label
	parts.append("[center][b]%s[/b]\n%s[/center]\n\n" % [
		data.name,
		data.ability_type.get_cast_label(data.is_passive)
	])

	# Cost, cd, cast time
	if data.mana_cost > 0:
		parts.append("[img]%s[/img] %d\n" % [MANA_ICON_PATH, data.mana_cost])
	if data.cooldown > 0:
		parts.append("[img]%s[/img] %0.1fs\n" % [COOLDOWN_ICON_PATH, data.cooldown])
	if data.cast_time > 0:
		parts.append("Cast time: %0.1fs\n" % data.cast_time)

	# Description
	parts.append("\n%s\n\n" % data.description)

	# Ability specific
	parts.append(spell_type.get_tooltip(ability))

	return "".join(parts)
