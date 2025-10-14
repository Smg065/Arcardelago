extends TextureRect
class_name CardSlot

@export var squarable : bool

var cardPrefab : PackedScene = load("res://Resources/CardUI.tscn")

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var dict : Dictionary = data as Dictionary
	if !dict.has("IsArcardelago"):
		return false
	if get_child_count() > 0:
		if !squarable:
			return false
		var curCard : CardUI = get_child(0)
		if curCard == data["CardUI"]:
			return false
		if !curCard.cardData.is_comparable(data["CardUI"].cardData):
			return false
		return get_child(0).square_stackable(data["CardUI"])
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var inCard : CardUI = data["CardUI"]
	#Move squarable data over
	if get_child_count() > 0:
		get_child(0).square_stack(inCard)
	else:
		#Move a single card as a child to the new location
		var cardToSetup : CardUI
		if inCard.compressedCardData.size() == 0:
			cardToSetup = inCard
			inCard.shift_parent(self)
		#Extract a single card and construct a new one to go here
		else:
			var newCard : CardUI = cardPrefab.instantiate()
			add_child(newCard)
			newCard.build(inCard.extract_data(1)[0])
			cardToSetup = newCard
		#Make it fit correctly
		cardToSetup.set_min_from_height(0)
		cardToSetup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		#Mouse controls exist here now
		mouse_filter = Control.MOUSE_FILTER_STOP
