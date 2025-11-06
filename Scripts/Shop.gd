extends GameScreen
class_name Shop

@export var shopCardPrefab : PackedScene
@export var itemButtonPrefab : PackedScene
@export var itemTable : Dictionary[ShopItemInfo, int]

@export var shopItemsHolder : HBoxContainer

@export var cardSeller : CardSlot
@export var sellButton : Button

@export var cardReleaser : CardSlot
@export var releaserButton : Button

var itemWeightMax : int
var currentCardpool : Array[CardData]

##Precalculate the shop info
func _ready() -> void:
	itemWeightMax = 0
	for eachValue in itemTable.values():
		itemWeightMax += eachValue

##Sets if this screen is active in the map viewer or not
func set_active(nState : bool, nInfo : Dictionary):
	super(nState, nInfo)
	if !nState:
		return
	setup_shop()

##Setup the shop data to be used
func setup_shop():
	for eachChild in shopItemsHolder.get_children():
		eachChild.queue_free()
	currentCardpool = Persist.game.current_cardpool()
	for i in 5:
		if randi_range(1,5)<=2:
			setup_item()
		else:
			setup_card()

##Adds an item from the item table based on a weighted roll
func setup_item():
	var newItemInfo : ShopItemInfo
	var newItem : ShopItemButton = itemButtonPrefab.instantiate()
	var weightedRoll := randi_range(1, itemWeightMax)
	for eachItem in itemTable:
		weightedRoll -= itemTable[eachItem]
		if weightedRoll <= 0:
			newItemInfo = eachItem
			break
	newItem.setup_info(newItemInfo, bought_item)
	shopItemsHolder.add_child(newItem)

##Adds a card from the cardpool, or a default card
func setup_card():
	var newCardSlotRoot : Control = shopCardPrefab.instantiate()
	var newCardSlot : ShopCard = newCardSlotRoot.get_child(0)
	var newCard : CardUI = newCardSlot.cardPrefab.instantiate()
	if currentCardpool.size() > 0 and randi_range(1, 3) != 1:
		var randomCard : CardData
		randomCard = currentCardpool.pick_random()
		currentCardpool.erase(randomCard)
		newCard.build(randomCard)
		randomCard.scout()
	else:
		newCard.build(CardData.new_default())
	newCardSlot.add_child(newCard)
	newCardSlot.setup_card(newCard)
	shopItemsHolder.add_child(newCardSlotRoot)

##Item Bought
func bought_item(boughtItem : ShopItemButton):
	Persist.game.itemHandler.spend(boughtItem.cost)
	Persist.game.itemHandler.received_item(boughtItem.itemInfo.name)

##Exit the shop
func leave_shop():
	var gameRoot : GameRoot = get_parent()
	gameRoot.scrollBox.return_cards()
	gameRoot.clear_map_pip()
	gameRoot.switch_scenes()
