extends TextureRect
class_name InventoryStamp

@export var stampType : String

func _get_drag_data(_at_position: Vector2) -> Variant:
	#Disable dragging uninteractable slots
	set_drag_preview(self.duplicate(0))
	return {"IsArcardelago" : true, "Type" : "Stamp", "StampType" : stampType}
