extends GameScreen
class_name Treasure

var cardPrefab : PackedScene = load("res://Resources/CardUI.tscn")
var currentCardpool : Array[CardData]
var itempool : Array[ItemInfo]
@export var optionPair : HBoxContainer
@export var slotPrefab : PackedScene
@export var overlayTextures : Array[TextureRect]
@export var lidBack : TextureRect

##Sets if this screen is active in the map viewer or not
func set_active(nState : bool, nInfo : Dictionary):
	if nState:
		#Overlay color
		var overlayColor : Color
		if nInfo.has("Region"):
			overlayColor = ColorCatagory.get_color(ColorCatagory.BASE_COLORS[nInfo["Region"]].colorType)
		else:
			overlayColor = Color.WHITE
		for eachTexture in overlayTextures:
			eachTexture.modulate = overlayColor
		
		#Apply the treasure data
		currentCardpool = Persist.game.current_cardpool()
		itempool = PD.treasureItemTable.keys()
		for twoEntries in 2:
			#Cards
			if randi_range(0, 1) == 1:
				var newSlot : CardSlot = slotPrefab.instantiate()
				optionPair.add_child(newSlot)
				var newCard : CardUI
				#Highest quality
				if randi_range(0, 1) == 1:
					newCard = pick_card_from_pool(currentCardpool)
				#Regular quality
				else:
					newCard = random_best_card()
				newSlot.add_child(newCard)
				newSlot.setup_card(newCard)
				newSlot.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				newSlot.isSource = true
				newSlot.playerInteractable = true
				newSlot.holding_updated.connect(card_selected)
			else:
			#Items
				var itemButton : MultiItemButton = multi_item()
				itemButton.alignment = HORIZONTAL_ALIGNMENT_FILL
				optionPair.add_child(itemButton)
	super(nState, nInfo)

##Setup a card UI based off the
func pick_card_from_pool(cardOptions : Array[CardData] = currentCardpool) -> CardUI:
	var newCard : CardUI = cardPrefab.instantiate()
	if cardOptions.size() > 0:
		var chosenCard = cardOptions.pick_random()
		newCard.build(chosenCard)
		currentCardpool.erase(chosenCard)
	else:
		newCard.build(CardData.new_default())
	return newCard

##Offer a single card of the highest quality you possibly can
func random_best_card() -> CardUI:
	var bestCards := PD.best_cards(currentCardpool)
	return pick_card_from_pool(bestCards)

##Offer multiple items of the given type
func multi_item() -> MultiItemButton:
	var randomItem : ItemInfo = itempool.pick_random()
	itempool.erase(randomItem)
	var itemButton : MultiItemButton = MultiItemButton.new()
	itemButton.setup_info(randomItem, item_claimed)
	itemButton.copies = PD.treasureItemTable[randomItem]
	return itemButton

##Get the number of copies of items to claim
func card_selected(_usedSlot : CardSlot):
	clear_options()
	to_world_map()

##Get the number of copies of items to claim
func item_claimed(toClaim : MultiItemButton):
	for copies in toClaim.copies:
		Persist.game.itemHandler.received_item(toClaim.itemInfo.name, false)
	Persist.game.itemHandler.update_inventory()
	clear_options()
	to_world_map()

##Remove all option buttons
func clear_options():
	for eachOption in optionPair.get_children():
		eachOption.queue_free()

##Exit the shop
func to_world_map():
	var gameRoot : GameRoot = get_parent()
	gameRoot.clear_map_pip()
	gameRoot.switch_scenes()
