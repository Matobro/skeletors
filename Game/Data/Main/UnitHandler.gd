extends Node

var all_units: Array = []
var units_by_player: Dictionary = {}

signal unit_died(unit)

func register_unit(unit):
	# Add unit to registry
	all_units.append(unit)

	# Add unit to player specific registry
	if not units_by_player.has(unit.owner_id):
		units_by_player[unit.owner_id] = []
	units_by_player[unit.owner_id].append(unit)

	# Connect signals
	unit.died.connect(_on_unit_died)

	# Initialize unit
	unit.init_unit()

func unregister_unit(unit):
	# Remove from registry
	all_units.erase(unit)

	# Remove from player specific registry
	if units_by_player.has(unit.owner_id):
		units_by_player[unit.owner_id].erase(unit)

func _on_unit_died(unit):
	unregister_unit(unit)
	emit_signal("unit_died", unit)

	if unit.owner_id == 10:
		for player in PlayerManager.get_all_players():
			if player.player_id != 10 and player.hero:
				player.hero.get_xp(unit.data.stats.xp_yield)

func get_units_by_player(owner_id):
	return units_by_player.get(owner_id, [])
