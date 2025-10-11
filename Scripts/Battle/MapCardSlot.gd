extends TextureRect
class_name CardSlot

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var dict : Dictionary = data as Dictionary
	if !dict.has("IsArcardelago"):
		return false
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var inCard : CardUI = data["CardUI"]
	inCard.get_parent().remove_child(inCard)
	add_child(inCard)
	inCard.set_min_from_height(0)
	inCard.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
