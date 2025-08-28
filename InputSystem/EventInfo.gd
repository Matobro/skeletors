extends RefCounted

## @tutorial: mouse_button, intent_type, clicked_position, clicked_unit, clicked_item, keys_pressed
class_name InputInfo

enum CursorButton { NONE, LEFT, RIGHT, MIDDLE }
enum IntentType { NONE, SELECT, BOX_SELECT, MOVE, ATTACK }

var mouse_button: CursorButton = CursorButton.NONE
var intent_type: IntentType = IntentType.NONE

var clicked_position: Vector2
var clicked_unit: Unit = null
var clicked_item: DroppedItem = null
var keys_pressed: Array = []
var drag_rect: Rect2 = Rect2()

func _to_string() -> String:
    return "[InputInfo button=%s intent=%s pos=%s unit=%s clicked_item=%s keys=%s]" % [
        CursorButton.keys()[mouse_button],
        IntentType.keys()[intent_type],
        clicked_position,
        clicked_unit,
        clicked_item,
        keys_pressed
    ]
