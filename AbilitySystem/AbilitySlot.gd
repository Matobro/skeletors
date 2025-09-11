extends Button

@onready var button_icon = $Icon
@onready var cooldown_label = $Cooldown

var ability: BaseAbility
var data: AbilityData
var max_cooldown

func _ready() -> void:
    ## Clear slot
    ability = null
    data = null
    max_cooldown = 0
    set_slot(null, null)

func _process(_delta: float) -> void:
    if !ability or !data:
        return

    ## Show cooldown animation
    var cooldown = ability.current_cooldown
    if cooldown > 0:
        cooldown_label.text = str("%0.1f" %cooldown)
        cooldown_label.visible = true
        button_icon.value = (cooldown / max_cooldown) * button_icon.max_value
        return
    
    cooldown_label.visible = false

## Links ui slot to unit ability
func set_slot(new_ability, new_data):
    # Clear previous data
    ability = null
    data = null
    visible = false
    # Set new data
    if new_ability and new_data:
        visible = true
        ability = new_ability
        data = new_data
        max_cooldown = data.cooldown
        button_icon.value = ability.current_cooldown
        disabled = data.is_passive
        button_icon.texture_under = data.icon
        button_icon.texture_progress = data.icon