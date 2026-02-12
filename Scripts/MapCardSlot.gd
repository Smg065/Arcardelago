extends TextureRect
class_name CardSlot

@export var playerInteractable : bool
@export var squarable : bool
@export var isSource : bool

var cardPrefab : PackedScene = load("res://Resources/CardUI.tscn")
@warning_ignore("unused_signal")
signal holding_updated(slot : CardSlot)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if !playerInteractable:
		return false
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var dict : Dictionary = data as Dictionary
	if not "IsArcardelago" in dict:
		return false
	if "Card" != dict["Type"]:
		return false
	var cardSource = data["CardUI"].get_parent()
	if cardSource is CardSlot:
		#No source to source dragging
		if cardSource.isSource or isSource:
			return false
	var curCard : CardUI = get_card()
	if curCard != null:
		if !squarable:
			return false
		if curCard == data["CardUI"]:
			return false
		if !curCard.cardData.is_comparable(data["CardUI"].cardData):
			return false
		return curCard.square_stackable(data["CardUI"])
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var inCard : CardUI = data["CardUI"]
	#Move squarable data over
	var curCard : CardUI = get_card()
	if curCard != null:
		curCard.square_stack(inCard)
	else:
		#Move a single card as a child to the new location
		if inCard.compressedCardData.size() == 0:
			inCard.shift_parent(self)
			setup_card(inCard)
			inCard.set_stack_multi()
		#Extract a single card and construct a new one to go here
		else:
			var newCard : CardUI = cardPrefab.instantiate()
			add_child(newCard)
			newCard.build(inCard.extract_data(1)[0])
			setup_card(newCard)
			inCard.set_stack_multi()
	holding_updated.emit(self)

##Make it fit correctly
func setup_card(cardToSetup : CardUI):
	cardToSetup.set_min_from_height(0)
	cardToSetup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	#Mouse controls exist here now
	mouse_filter = Control.MOUSE_FILTER_STOP

##Gets the card that's in the slot
func get_card() -> CardUI:
	if get_child_count() <= 0:
		return null
	return get_child(0) as CardUI

##Make the card cease
func release_card():
	var childCard := get_card()
	if childCard == null:
		return
	childCard.queue_free()
