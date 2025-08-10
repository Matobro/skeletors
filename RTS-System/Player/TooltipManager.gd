extends Node

var player_tooltips = {}

func register_player_tooltip(player_id: int, tooltip_panel: Control):
    player_tooltips[player_id] = tooltip_panel

func show_tooltip(player_id: int, text: String, position: Vector2):
    if player_id in player_tooltips:
        player_tooltips[player_id].show_tooltip(text, position)

func hide_tooltip(player_id: int):
    if player_id in player_tooltips:
        player_tooltips[player_id].hide_tooltip()