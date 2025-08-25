extends Node

class_name UIUnitStats

@onready var portrait_panel = $"../PortraitPanel"
@onready var portrait_bg = $"../PortraitPanel/PortraitBG"
@onready var portrait_sprite = $"../PortraitPanel/PortraitBG/PortraitSprite"
@onready var portrait_stylebox = portrait_panel.get("theme_override_styles/panel")

## UI elements that should display tooltip when hovered over
@onready var stat_names = {
	"hero_stats": $"../HeroStats",
	"unit_stats": $"../UnitStats",
	"ui_bars": $"../UIBars",
	"damage": $"../UnitStats/Damage",
	"armor": $"../UnitStats/Armor",
	"str": $"../HeroStats/Str",
	"agi": $"../HeroStats/Agi",
	"int": $"../HeroStats/Int",
	"xp_bar": $"../HeroStats/XpBar",
	"hp_bar": $"../UIBars/HpBar",
	"mp_bar": $"../UIBars/ManaBar"
}

## UI Labels that display the actual values
@onready var stat_labels = {
	"damage": $"../UnitStats/DamageValue",
	"armor": $"../UnitStats/ArmorValue",
	"str": $"../HeroStats/StrValue",
	"agi": $"../HeroStats/AgiValue",
	"int": $"../HeroStats/IntValue",
	"name": $"../UnitStats/Name",
	"hp_bar": $"../UIBars/HpValue",
	"mp_bar": $"../UIBars/ManaValue",
	"level": $"../HeroStats/Level"
}

func show_portrait(unit: Unit):
	portrait_sprite.sprite_frames = unit.data.avatar
	portrait_sprite.play("idle")
	var portrait_color = PlayerManager.get_player_color(unit.owner_id)
	var faded_color = portrait_color.lerp(Color.BLACK, 0.75)
	portrait_stylebox.bg_color = faded_color

	scale_portrait()
	portrait_panel.visible = true

func hide_unit_stats():
	stat_names["unit_stats"].visible = false
	stat_names["hero_stats"].visible = false

func hide_ui_bars():
	stat_names["ui_bars"].visible = false
	portrait_panel.visible = false

func show_ui_bars(unit: Unit):
	stat_names["hp_bar"].max_value = unit.data.stats.max_health
	stat_names["hp_bar"].value = unit.data.stats.current_health
	stat_labels["hp_bar"].text = str(int(unit.data.stats.current_health), "/", int(unit.data.stats.max_health))

	stat_names["mp_bar"].max_value = unit.data.stats.max_mana
	stat_names["mp_bar"].value = unit.data.stats.current_mana
	stat_labels["mp_bar"].text = str(int(unit.data.stats.current_mana), "/", int(unit.data.stats.max_mana))

	stat_names["ui_bars"].visible = true
	show_portrait(unit)

func show_unit_stats(unit: Unit):
	show_ui_bars(unit)

	stat_labels["name"].text = unit.data.name
	stat_labels["damage"].text = str(StatModifiers.get_damage_range(unit.data.stats.attack_damage, unit.data.stats.attack_dice_roll))
	stat_labels["armor"].text = str(unit.data.stats.armor)

	stat_names["unit_stats"].visible = true

	if unit is Hero:
		stat_labels["str"].text = str(unit.data.stats.strength)
		stat_labels["agi"].text = str(unit.data.stats.agility)
		stat_labels["int"].text = str(unit.data.stats.data.intelligence)

		stat_names["xp_bar"].max_value = unit.data.hero.get_xp_for_next_level() - unit.data.hero.get_xp_for_current_level()
		stat_names["xp_bar"].value = unit.data.stats.xp - unit.data.hero.get_xp_for_current_level()

		stat_labels["level"].text = str(unit.data.stats.level)
		
		stat_names["hero_stats"].visible = true
	else:
		stat_names["hero_stats"].visible = false

## Zoom = how close the portrait is
## y_offset_ratio more than 0.5 moves sprite up, less than 0.5 moves sprite down
func scale_portrait(zoom: float = 3.0, y_offset_ratio: float = 0.4):
	var frame_texture = portrait_sprite.sprite_frames.get_frame_texture("idle", 0)
	var frame_size = frame_texture.get_size()
	var bg_size = portrait_bg.size

	var scale_ratio = bg_size / frame_size
	var final_scale = min(scale_ratio.x, scale_ratio.y) * zoom
	portrait_sprite.scale = Vector2.ONE * final_scale

	var scaled_frame_size = frame_size * final_scale

	var pos_x = bg_size.x / 2 - scaled_frame_size.x / 2
	var pos_y = bg_size.y / 2 - scaled_frame_size.y * y_offset_ratio

	portrait_sprite.position = Vector2(pos_x, pos_y)
