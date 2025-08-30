extends RefCounted

func get_info_text(ability_data: AbilityData) -> String:
    var text = str(
        "Right click to cast ", ability_data.name
    )

    return text
