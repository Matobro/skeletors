extends Node

var all_units: Array = []
var heroes: Array = []
var units_by_player: Dictionary = {}

var regen_tick := 0.0
const REGEN_INTERVAL := 1.0

signal unit_died(unit)

func _process(delta):
	regen_tick += delta
	if regen_tick >= REGEN_INTERVAL:
		regen_tick = 0.0
		for unit in all_units:
			if is_instance_valid(unit.unit_combat) and unit.unit_combat.has_method("regenate_health"):
				unit.unit_combat.regenate_health()
				unit.unit_combat.regenate_mana()
	
func register_unit(unit):
	# Add unit to registry
	all_units.append(unit)

	# If hero add to hero registry
	if unit.data.unit_type == "hero" and !heroes.has(unit):
		print("Added hero")
		heroes.append(unit)

	# Add unit to player specific registry
	if not units_by_player.has(unit.owner_id):
		units_by_player[unit.owner_id] = []
	units_by_player[unit.owner_id].append(unit)

	# Connect signals
	unit.died.connect(_on_unit_died)

func unregister_unit(unit):
	# Remove from registry
	all_units.erase(unit)

	# Remove from player specific registry
	if units_by_player.has(unit.owner_id):
		units_by_player[unit.owner_id].erase(unit)

func _on_unit_died(unit):
	if !is_instance_valid(unit):
		return
		
	unregister_unit(unit)
	emit_signal("unit_died", unit)

	if unit.owner_id == 10:
		for hero in heroes:
			if is_instance_valid(hero) and hero.owner_id != 10:
				hero.get_xp(unit.data.stats.xp_yield)

func get_units_by_player(owner_id) -> Array:
	return units_by_player.get(owner_id, [])
