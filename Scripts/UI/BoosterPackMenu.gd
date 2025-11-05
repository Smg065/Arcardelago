extends CanvasLayer
class_name BoosterPackUI

@export var cardPrefab : PackedScene = preload("res://Resources/CardUI.tscn")
@export var cardSlots : Array[CardSlot]

func _ready() -> void:
	for eachSlot in cardSlots:
		eachSlot.holding_updated.connect(check_slot_empty)

##Display the next booster pack info
func setup():
	show()
	var cardpool := Persist.game.current_cardpool()
	for eachSlot in cardSlots:
		var nextCard : CardUI = cardPrefab.instantiate()
		eachSlot.add_child(nextCard)
		var nextData : CardData
		if cardpool.size() > 0:
			nextData = cardpool.pick_random()
			cardpool.erase(nextData)
			nextData.scout()
		else:
			nextData = CardData.new_default()
		nextCard.build(nextData)

##Sent when you remove a card from the presented options
func check_slot_empty(_checkSlot : CardSlot):
	var anyOpen : bool = false
	for eachSlot in cardSlots:
		for eachChild in eachSlot.get_children():
			if !eachChild.is_queued_for_deletion():
				anyOpen = true
	if anyOpen:
		close()

##Close this if there are no more booster packs awaiting
func close():
	for eachSlot in cardSlots:
		for eachChild in eachSlot.get_children():
			eachChild.queue_free()
	if Persist.game.itemHandler.try_event("Booster Pack"):
		hide()
		setup()
	else:
		hide()
