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
		for slot in ability_grid.get_children(false):
			ability_slots.append(slot)
			slot.connect("mouse_entered", Callable(self, "on_mouse_hover").bind(slot))
			slot.connect("mouse_exited", Callable(self, "on_mouse_hover_exit"))

## Clears ui and then links selected unit abilities to ui slots
func update_action_menu(abilities: Array[BaseAbility] = []):
	clear_abilities()

	if abilities:
		for i in range(abilities.size()):
			ability_slots[i].set_slot(abilities[i], abilities[i].ability_data)

func clear_abilities():
	for slot in ability_slots:
		slot.set_slot(null, null)

func on_mouse_hover(slot):
	var text = get_slot_text(slot)
	var pos = action_panel.global_position
	TooltipManager.show_tooltip(player_id, text, pos)

func on_mouse_hover_exit():
	TooltipManager.hide_tooltip(player_id)

func get_slot_text(slot) -> String:
	var data = slot.data
	var parts := []
	
	# Name + targeting
	parts.append("[center][b]" + data.name + "[/b]"+ "\n" + data.ability_type.get_cast_label(data.is_passive) + "[/center]\n\n")

	# Mana
	if data.mana_cost > 0:
		parts.append("[img]" + MANA_ICON_PATH +"[/img] " + str(data.mana_cost) + "\n")
	
	# Cooldown
	if data.cooldown > 0:
		parts.append("[img]" + COOLDOWN_ICON_PATH +"[/img] " + str(data.cooldown) + "s" + "\n\n")

	# Description
	parts.append(data.description + "\n")

	# Effects
	parts.append("\n")
	for effect in data.effects:
		parts.append(format_effect(effect) + "\n")

	return "".join(parts) # the fuck is this syntax

func format_effect(effect: EffectData) -> String:
	match effect.effect_type:
		"Damage":
			return "Damage: " + format_value(effect.amount)
		"Heal":
			return "Heal: " + format_value(effect.amount)
		"Heal_Mana":
			return "Mana Heal: " + format_value(effect.amount)
		"Buff":
			return get_buff_type(effect)
		"Stun":
			return "Stun: " + format_value(effect.duration) + "s"
		"Summon":
			#return "Summons: " + 
			pass 
	return ""

func format_value(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(value))
	else:
		return str(value)

func get_buff_type(effect: EffectData) -> String:
	match effect.stat:
		"armor":
			return "Armor: " + format_value(effect.amount)

	return ""
	
