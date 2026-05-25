extends AspectRatioContainer
class_name CardUI

@export_group("UI Info", "uiCard")
@export var uiCardNameLabel : AutoSizeRichTextLabel
@export var uiCardItemFlagLabel : AutoSizeRichTextLabel
@export var uiCardWordTypesLabel : AutoSizeRichTextLabel
@export var uiCardPhoneticsLabel : AutoSizeRichTextLabel
@export var uiCardGameLabel : AutoSizeRichTextLabel
@export var uiCardBackColor : ColorSpectrumRect
@export var uiCardPipColor : ColorPipDisplay
@export var uiCardSetPipColor : ColorPipDisplay
@export var uiCardBandColor : ColorSpectrumRect
@export var uiCardHealth : AutoSizeLabel
@export var uiCardDamage : AutoSizeLabel
@export var uiCardCount : AutoSizeLabel
@export var uiCardAbilities : AutoSizeRichTextLabel
@export var uiCardStampContainer : HBoxContainer
@export var uiCardArt : TextureRect

@export var playerPip : Texture2D
@export var enemyPip : Texture2D
@export var clearedEnemyPip : Texture2D
@export var bossPip : Texture2D
@export var clearedBossPip : Texture2D

var fadeState : bool
var cardFade : float = 0
const PLAYER_NAME_COLOR = "222222"

@export var cardData : CardData
var cardName : String
var compressedCardData : Array[CardData]
var partialFiltered : Array[bool]

func _process(delta: float) -> void:
	var fadeModi : float = -4
	if fadeState == Persist.imageByDefault:
		fadeModi = 4
	cardFade = clampf(cardFade + (delta * fadeModi), 0, 1)
	uiCardArt.modulate = Color.WHITE.lerp(Color.TRANSPARENT, cardFade)

func build(nCardData : CardData):
	cardData = nCardData
	new_compression_size()
	uiCardBackColor.colors = cardData.colors
	uiCardPipColor.colors = cardData.colors
	uiCardBackColor.build(cardData.fadeAngle)
	if cardData.isDefault:
		cardName = "Default"
		uiCardBandColor.hide()
		uiCardWordTypesLabel.hide()
		uiCardPhoneticsLabel.hide()
		if cardData.enemyCard:
			uiCardPipColor.default(enemyPip)
		else:
			uiCardPipColor.default(playerPip)
		uiCardBackColor.default()
	else:
		cardName = " ".join([cardData.nameData.name, cardData.gameCardset.game])
		if cardData.enemyCard:
			uiCardBandColor.hide()
			if cardData.apItemFlags == 3:
				uiCardPipColor.build(bossPip, clearedBossPip)
			else:
				uiCardPipColor.build(enemyPip, clearedEnemyPip)
		else:
			uiCardBandColor.show()
			uiCardPipColor.build(playerPip)
			update_region_band()
		uiCardSetPipColor.colors = cardData.gameCardset.setColor
		uiCardSetPipColor.build(playerPip)
	
	name = cardName
	update_rich_texts()
	update_stamps()
	set_stack_multi()
	check_cleared()

func check_cleared():
	if cardData.is_cleared():
		if cardData.enemyCard:
			uiCardPipColor.mark_cleared()
		else:
			uiCardBackColor.modulate = Color(1,1,1,0.5)

func update_rich_texts():
	#Universal Data
	var nameForUse : String
	if cardData.nameData != null:
		nameForUse = cardData.nameData.name
	else:
		nameForUse = "Default"
	uiCardNameLabel.text = "[center][bgcolor=snow][color=black]%s" % nameForUse
	uiCardItemFlagLabel.text = "[center]" + cardData.rich_item_flags()
	uiCardNameLabel.do_resize_text()
	uiCardItemFlagLabel.do_resize_text()
	#Display stats
	var allAbilityText := PackedStringArray()
	for eachAbility in cardData.abilities:
		allAbilityText.append(eachAbility.construct_text())
	uiCardAbilities.text = "[color=black]%s[/color]" % "\n\n".join(allAbilityText)
	#Degault cards can't have special data
	update_players_display()
	if cardData.isDefault:
		return
	uiCardWordTypesLabel.text = "[center][bgcolor=snow][color=black]" + "/".join(cardData.unique_parts_of_speech())
	uiCardPhoneticsLabel.text = "[center][bgcolor=slategray]" + ", ".join(cardData.rich_phonetic_symbols())
	uiCardWordTypesLabel.do_resize_text()
	uiCardPhoneticsLabel.do_resize_text()

##Set the colors of the new region band
func update_region_band():
	if cardData.isDefault or cardData.enemyCard:
		return
	var apIds : PackedInt32Array
	#Normal APID's
	for cardIndex in compressedCardData.size():
		if !partialFiltered[cardIndex]:
			apIds.append(compressedCardData[cardIndex].apId)
	#Partial Filtered APID's
	if !partialFiltered[-1]:
		apIds.append(cardData.apId)
	var colorIds : PackedInt32Array = ap_ids_to_band_colors(apIds)
	var bandColors : int = 0
	for eachEntry in colorIds:
		bandColors += roundi(pow(2, eachEntry))
	uiCardBandColor.colors = bandColors
	uiCardBandColor.build(PI)

##Gets the array of band colors from a collection of APIDs
static func ap_ids_to_band_colors(apIds : PackedInt32Array) -> PackedInt32Array:
	var colorIds : PackedInt32Array
	for eachId in apIds:
		var eachColor : int = floori((eachId - 65000.0) / 100.0)
		if !colorIds.has(eachColor):
			colorIds.append(eachColor)
	return colorIds

##Show all the players these cards belong to
func update_players_display():
	var allPlayerNames : PackedStringArray
	#Default card name
	if !partialFiltered[-1]:
		allPlayerNames.append(cardData.playerName)
	#Alt players names
	for cardIndex in compressedCardData.size():
		if !partialFiltered[cardIndex]:
			if !allPlayerNames.has(compressedCardData[cardIndex].playerName):
				allPlayerNames.append(compressedCardData[cardIndex].playerName)
	#Display
	var playersNames : String = ", ".join(allPlayerNames).replace("[", "[lb]")
	var gameName : String
	if cardData.isDefault:
		gameName = "Cardelago"
		playersNames = Archipelago.conn.slot_data["player_name"]
	else:
		gameName = cardData.gameCardset.game
	
	uiCardGameLabel.text = "[center][color=black][i][u]%s[/u][/i][/color][color=%s]\n%s" % [gameName, PLAYER_NAME_COLOR, playersNames]
	uiCardGameLabel.tooltip_text = "%s\n%s" % [gameName, playersNames]
	uiCardGameLabel.do_resize_text()

##Update stamps and stamp effects on this card
func update_stamps():
	for eachChild in uiCardStampContainer.get_children():
		eachChild.queue_free()
	var stampCounts : Dictionary[String, int]
	for eachStamp in cardData.stamps:
		if eachStamp in stampCounts:
			stampCounts[eachStamp] += 1
		else:
			stampCounts[eachStamp] = 1
	for eachIndex in compressedCardData.size():
		if partialFiltered[eachIndex]:
			continue
		var eachCard := compressedCardData[eachIndex]
		for eachStamp in eachCard.stamps:
			if eachStamp in stampCounts:
				stampCounts[eachStamp] += 1
			else:
				stampCounts[eachStamp] = 1
	for eachStamp in stampCounts:
		uiCardStampContainer.add_child(StampButton.generate_button(self, eachStamp, stampCounts[eachStamp]))

##Show how many cards of this type you have
func update_card_count_display():
	var totalCards = 1 + compressedCardData.size()
	for eachFiltered in partialFiltered:
		if eachFiltered:
			totalCards -= 1
	if totalCards > 1:
		uiCardCount.show()
		uiCardCount.text = str(totalCards)
	else:
		uiCardCount.hide()

func set_min_from_height(inHeight : int):
	custom_minimum_size = Vector2(ceili(inHeight * ratio), inHeight)

##Tries to combine cards into eachother for visual clarity
func try_compress_card(inCard : CardData) -> bool:
	if !inCard.is_comparable(cardData):
		return false
	compressedCardData.append(inCard)
	new_compression_size()
	update_compressed_vis()
	return true

##Tries to remove card data from this UI
func try_remove_card(inCard : CardData) -> bool:
	if compressedCardData.has(inCard):
		compressedCardData.erase(inCard)
		new_compression_size()
		update_compressed_vis()
		return true
	if cardData == inCard:
		if compressedCardData.size() == 0:
			queue_free()
			try_notify_slot_moved(get_parent())
		else:
			build(compressedCardData.pop_front())
		return true
	return false

##Update compressed visuals
func update_compressed_vis():
	update_stamps()
	update_region_band()
	update_players_display()
	update_card_count_display()

##Card compression changed
func new_compression_size():
	partialFiltered.resize(compressedCardData.size() + 1)

##Changes card visibility based on filters
func filter(commands : Dictionary[String, Array]) -> void:
	#Typings check
	if commands.has("Types"):
		if !commands["Types"].has(cardData.stringify_item_quality()):
			hide()
			return
		#Defaults only care about this filter
		elif cardData.isDefault:
			show()
			return
	#Filter non-defaults out when there's no type strings
	elif cardData.isDefault:
		visible = commands.size() <= 0
		return
	#Game is also straight forward
	if commands.has("Games"):
		if !commands["Games"].has(cardData.gameCardset.game):
			hide()
			return
	if commands.has("Colors"):
		var allColors : PackedStringArray = cardData.stringify_colors()
		#Colorless just checks if colorless is a command or not, always
		if allColors[0] == "Colorless":
			if !commands["Colors"].has("Colorless"):
				hide()
				return
		else:
			if commands["Colors"].has("Exact Match"):
				allColors.insert(0, "Exact Match")
				if commands["Colors"].size() > 0:
					if Array(allColors) != commands["Colors"]:
						hide()
						return
					else:
						print("%s != %s" % [allColors, commands["Colors"]])
			else:
				var passes : bool = false
				for eachColor in commands["Colors"]:
					if allColors.has(eachColor):
						passes = true
						break
				if !passes:
					hide()
					return
	#Partial Filters
	if commands.has("Players"):
		#Filter out if it's missing the player name
		partialFiltered[-1] = !commands["Players"].has(cardData.playerName)
		for eachIndex in compressedCardData.size():
			partialFiltered[eachIndex] = !commands["Players"].has(compressedCardData[eachIndex].playerName)
	else:
		#Disable all partial filters
		for eachIndex in partialFiltered.size():
			partialFiltered[eachIndex] = false
	#If everything is hidden, just hide
	if !(false in partialFiltered):
		hide()
		return
	else:
		update_compressed_vis()
	show()

func _get_drag_data(_at_position: Vector2) -> Variant:
	#Disable dragging uninteractable slots
	var cardParent = get_parent()
	if cardParent is CardSlot:
		if !cardParent.playerInteractable:
			return null
		if cardParent is ShopCard:
			if !cardParent.purchasable():
				return null
	#Create a preview of this card while it moves along
	var cardPreview = self.duplicate(0)
	cardPreview.custom_minimum_size = Vector2(64 * ratio, 64)
	cardPreview.set_anchors_and_offsets_preset(PRESET_CENTER)
	
	cardPreview.size = cardPreview.custom_minimum_size
	cardPreview.pivot_offset = cardPreview.size / 2
	cardPreview.z_index = 7
	set_drag_preview(self.duplicate(0))
	return {"IsCardelago" : true, "Type" : "Card", "CardUI" : self}

##Changes the cards parent and sets card slots
func shift_parent(nParent : Node):
	var parent = get_parent()
	warn_scrollbox_battlecard(all_card_data())
	update_card_slot_mouse()
	parent.remove_child(self)
	nParent.add_child(self)
	try_notify_slot_moved(parent)

##Notify scrollbox when a card is placed for battles
func warn_scrollbox_battlecard(movingData : Array[CardData]):
	var parent = get_parent()
	if parent.name == "CardGrid":
		var cardScrollbox = parent.get_parent().get_parent()
		cardScrollbox.battleCards.append_array(movingData)

##Notify card slots when data moves, and add cards you buy or find
func try_notify_slot_moved(oldParent):
	if oldParent is CardSlot:
		if oldParent is ShopCard:
			Persist.game.itemHandler.spend(oldParent.cardCost, self)
			oldParent.purchase()
		if oldParent.isSource:
			Persist.currentCards.append_array(all_card_data())
		oldParent.holding_updated.emit(oldParent as CardSlot)

##Allow the slot to stop taking mouse events
func update_card_slot_mouse():
	var parent = get_parent()
	if parent is CardSlot:
		parent.mouse_filter = Control.MOUSE_FILTER_PASS

##The number of stacks this would have on a card slot
func stack_size(includeStamps : bool = true) -> int:
	var bonusStacks : int = 0
	if includeStamps:
		bonusStacks += cardData.stamps.count("Square")
		for eachIndex in compressedCardData.size():
			if not partialFiltered[eachIndex]:
				bonusStacks += compressedCardData[eachIndex].stamps.count("Square")
	return floori(log(partialFiltered.size() + bonusStacks) / log(2))

##The number of cards needed to up the stack
func to_next_stack() -> int:
	var stackSize := stack_size(false)
	var output := roundi(pow(2, stackSize + 1)) - partialFiltered.size()
	return output

##If this card can be square stacked
func square_stackable(inUi : CardUI) -> bool:
	var inCount : int = inUi.partialFiltered.count(false)
	return inCount >= to_next_stack()

##Make the cards build to a new stack
func square_stack(inUi : CardUI) -> void:
	var extractedData := inUi.extract_data(to_next_stack())
	compressedCardData.append_array(extractedData)
	new_compression_size()
	update_compressed_vis()
	set_stack_multi()

##Multiply your health and damage by the stack size. Set to false to set it do default instead.
func set_stack_multi(showStacked : bool = true):
	var multi : int = 1
	if showStacked:
		multi = stack_size() + 1
	uiCardHealth.text = str(cardData.baseHealth * multi)
	uiCardDamage.text = str(cardData.baseAttack * multi)

##Applies the current damage and returns false if the card is dead
func apply_damage(sustainedDamage : int) -> bool:
	var newHealth := maxi((cardData.baseHealth * (stack_size() + 1)) - sustainedDamage, 0)
	uiCardHealth.text = str(newHealth)
	if newHealth == 0:
		modulate = Color.SLATE_GRAY
		return false
	modulate = Color.WHITE
	return true

##Extract the given number of non partial-filtered card data entries.[br]
##Leave empty to extract all unfiltered entries.
func extract_data(toExtract : int = -1) -> Array[CardData]:
	if toExtract == -1:
		toExtract = partialFiltered.count(false)
	var output : Array[CardData]
	#Grab all the unfiltered nodes to extract
	for eachIndex in compressedCardData.size():
		if !partialFiltered[eachIndex]:
			output.append(compressedCardData[eachIndex])
			toExtract -= 1
		if toExtract <= 0:
			break
	#Remove the outputs
	for eachExtract in output:
		var removeIndex := compressedCardData.find(eachExtract)
		compressedCardData.remove_at(removeIndex)
		partialFiltered.remove_at(removeIndex)
	#If there's more to extract, try your main card
	if toExtract == 1:
		if !partialFiltered[-1]:
			output.append(cardData)
			#Do we just delete, or reassign owner and hide?
			if compressedCardData.size() > 0:
				build(compressedCardData.pop_back())
				hide()
			else:
				update_card_slot_mouse()
				queue_free()
				try_notify_slot_moved(get_parent())
			toExtract -= 1
	update_compressed_vis()
	if get_parent() is CardSlot:
		set_stack_multi()
	#Catch broken data extractions
	if toExtract > 0:
		push_warning("Can't extract all card data!")
	warn_scrollbox_battlecard(output)
	return output

##Returns all card data in this card UI
func all_card_data() -> Array[CardData]:
	var output : Array[CardData]
	output.append(cardData)
	output.append_array(compressedCardData)
	return output

##Card value
func card_value(useDifficulty : bool = true) -> int:
	var output : int = 0
	for eachCard in all_card_data():
		output += eachCard.card_value(useDifficulty)
	return output

##Check if you're allowed to drop a stamp on this card
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	#Get the data type
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var dict : Dictionary = data as Dictionary
	if not "IsCardelago" in dict:
		return false
	if "Stamp" != data["Type"]:
		return false
	#Given it's a stamp
	var stampType : String = data["StampType"]
	var hasWithoutStamp : bool = false
	#Hint stamps only care about if there's a hint for the card or not
	if stampType == "Hint":
		#TODO: You need enough hint points
		#And to not already be hinted
		if cardData.is_hinted():
			return false
	#Only hint stamps and harmony stamps can go on enemies. You can use a harmony stamp to bypass this.
	else:
		#Check if you have a stamp of that type in your inventory
		var curInventory := Persist.game.itemHandler.current_inventory()
		if not "%s Stamp" % stampType in curInventory.items:
			return false
		if cardData.enemyCard != ("Harmony" in cardData.stamps or stampType == "Harmony"):
			return false
	#Stamps of the same type cannot be stacked
	for eachCard in all_card_data():
		if stampType in eachCard.stamps:
			continue
		hasWithoutStamp = true
		break
	if not hasWithoutStamp:
		return false
	return true

##Apply a stamp to this card
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var stampType : String = data["StampType"]
	if stampType == "Hint":
		##Call for a hint here
		return
	#Stamps of the same type cannot be stacked
	for eachCard in all_card_data():
		if stampType in eachCard.stamps:
			continue
		eachCard.stamp(stampType)
		update_stamps()
		#Harmony stamped cards need to go into your inventory
		if stampType == "Harmony":
			Persist.gain_card(self.cardData)
			queue_free()
		return

##Calls when you press the gold stamp release button
func gold_stamp_release():
	if "Gold" in cardData.stamps:
		cardData.release()
		Persist.game.itemHandler.received_item("Treasure")
		#Do we just delete, or reassign owner and hide?
		if compressedCardData.size() > 0:
			build(compressedCardData.pop_back())
			hide()
		else:
			update_card_slot_mouse()
			queue_free()
			try_notify_slot_moved(get_parent())
		return
	#Stamps of the same type cannot be stacked
	var toRemove = null
	for eachIndex in compressedCardData.size():
		if partialFiltered[eachIndex]:
			continue
		if "Gold" in compressedCardData[eachIndex].stamps:
			toRemove = eachIndex
			break
	if toRemove != null:
		partialFiltered.remove_at(toRemove)
		compressedCardData[toRemove].release()
		compressedCardData.remove_at(toRemove)
		Persist.game.itemHandler.received_item("Treasure")


func card_art_mouseover(nFadeState : bool) -> void:
	fadeState = nFadeState
