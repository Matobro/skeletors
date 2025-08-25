extends Button

class_name InventorySlot

var item: ItemData

func set_item(new_item: ItemData) -> void:
    item = new_item
    if item:
        $TextureRect.texture = item.icon
        visible = true
    else:
        $TextureRect.texture = null
        visible = true