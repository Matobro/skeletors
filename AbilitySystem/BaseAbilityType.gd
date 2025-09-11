## Overridden in each ability type

extends Resource

class_name BaseAbilityType

func get_cast_label(is_passive: bool) -> String:
    return "[ABILITY]"
    
func cast(_context: CastContext):
    pass