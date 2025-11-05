extends CardSlot
class_name ShopCard

##How much it costs to buy this card
@export var cardCost : int
##How much it 
@export var costLabel : Label

func setup_card(cardToSetup : CardUI):
	var newCost := (cardToSetup.cardData.card_quality() + 1)
	cardCost = newCost
	display_cost()
	super(cardToSetup)

##Update the cost display
func display_cost():
	costLabel.text = "%sG" % cardCost

##If you can purchase this card or not
func purchasable() -> bool:
	return Persist.game.itemHandler.currentMoney >= cardCost

func purchase():
	costLabel.text = "SOLD"
	playerInteractable = false
