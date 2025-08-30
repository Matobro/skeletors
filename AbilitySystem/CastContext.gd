extends RefCounted

## @tutorial: [caster], [index], [target_position], [target_unit], [shift], [ability_data]
class_name CastContext

var caster: Unit
var index: int
var target_position: Vector2
var target_unit: Unit
var shift: bool = false
var ability: BaseAbility