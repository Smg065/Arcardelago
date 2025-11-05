extends GameScreen

@export var backdrop : TextureRect
@export var backdropOptions : Array[Texture2D]
@export var cardSlots : Array[CardSlot]
@export var releaseButton : Button
var offeringRequired : bool

func _ready() -> void:
	for eachSlot in cardSlots:
		eachSlot.holding_updated.connect(offerings_changed)

##Sets if this screen is active in the map viewer or not
func set_active(nState : bool, nInfo : Dictionary):
	visible = nState
	if !visible:
		return
	backdrop.texture = backdropOptions[nInfo["Region"]]
	match Persist.difficulty:
		#Easy
		0:
			for eachSlot in cardSlots:
				eachSlot.show()
			offeringRequired = false
		#Normal
		1:
			cardSlots[1].show()
			cardSlots[2].hide()
			offeringRequired = true
		#Hard
		2:
			cardSlots[1].hide()
			cardSlots[2].hide()
			offeringRequired = true
	releaseButton.disabled = offeringRequired

##Figure out if you've offered enough cards or not
func offerings_changed(_slot : CardSlot):
	for eachSlot in cardSlots:
		for eachChild in eachSlot.get_children():
			if !eachChild.is_queued_for_deletion():
				releaseButton.disabled = false
				return
	releaseButton.disabled = offeringRequired

##Release the cards
func release_cards():
	for eachSlot in cardSlots:
		for eachChild in eachSlot.get_children():
			if !eachChild.is_queued_for_deletion():
				eachChild = eachChild as CardUI
				for eachCard in eachChild.all_card_data():
					if !eachCard.isDefault and !eachCard.enemyCard:
						eachCard.release()
				eachChild.queue_free()
	var gameRoot : GameRoot = get_parent()
	gameRoot.clear_map_pip()
	gameRoot.switch_scenes()
