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

@export var playerPip : Texture2D
@export var enemyPip : Texture2D
@export var bossPip : Texture2D

const PLAYER_NAME_COLOR = "222222"

@export var cardData : CardData
var cardName : String
var compressedCardData : Array[CardData]
var partialFiltered : Array[bool]

func build(nCardData : CardData):
	cardData = nCardData
	partialFiltered.resize(compressedCardData.size() + 1)
	if cardData.isDefault:
		cardName = "Default"
		name = cardName
		uiCardWordTypesLabel.text = ""
		uiCardPhoneticsLabel.text = ""
		uiCardGameLabel.text = ""
		uiCardBandColor.hide()
		if cardData.enemyCard:
			uiCardPipColor.default(enemyPip)
		else:
			uiCardPipColor.default(playerPip)
		uiCardBackColor.default()
		update_rich_texts()
		return
	cardName = " ".join([cardData.nameData.name, cardData.gameCardset.game])
	name = cardName
	uiCardBackColor.colors = cardData.colors
	uiCardPipColor.colors = cardData.colors
	uiCardSetPipColor.colors = cardData.gameCardset.setColor
	uiCardSetPipColor.build(playerPip)
	uiCardBackColor.build(cardData.fadeAngle)
	if cardData.enemyCard:
		uiCardBandColor.hide()
		if cardData.apItemFlags == 3:
			uiCardPipColor.build(bossPip)
		else:
			uiCardPipColor.build(enemyPip)
	else:
		uiCardBandColor.show()
		uiCardPipColor.build(playerPip)
		update_region_band()
	update_rich_texts()

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
	
	#Degault cards can't have special data
	if cardData.isDefault:
		return
	uiCardWordTypesLabel.text = "[center][bgcolor=snow][color=black]" + "/".join(cardData.unique_parts_of_speech())
	uiCardPhoneticsLabel.text = "[center][bgcolor=slategray]" + ", ".join(cardData.rich_phonetic_symbols())
	uiCardWordTypesLabel.do_resize_text()
	uiCardPhoneticsLabel.do_resize_text()
	update_players_display()

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
	var colorIds : PackedInt32Array
	for eachId in apIds:
		var eachColor : int = floori((eachId - 65000.0) / 100.0)
		if !colorIds.has(eachColor):
			colorIds.append(eachColor)
	var bandColors : int = 0
	for eachEntry in colorIds:
		bandColors += roundi(pow(2, eachEntry))
	uiCardBandColor.colors = bandColors
	uiCardBandColor.build(PI)

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
	uiCardGameLabel.text = "[center][color=black][i][u]%s[/u][/i][/color][color=%s]\n%s" % [cardData.gameCardset.game, PLAYER_NAME_COLOR, playersNames]
	uiCardGameLabel.tooltip_text = "%s\n%s" % [cardData.gameCardset.game, playersNames]
	uiCardGameLabel.do_resize_text()

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

##Update compressed visuals
func update_compressed_vis():
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
		hide()
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
	var cardPreview = self.duplicate(0)
	cardPreview.custom_minimum_size = Vector2(64 * ratio, 64)
	cardPreview.set_anchors_and_offsets_preset(PRESET_CENTER)
	
	cardPreview.size = cardPreview.custom_minimum_size
	cardPreview.pivot_offset = cardPreview.size / 2
	cardPreview.z_index = 7
	set_drag_preview(self.duplicate(0))
	return {"IsArcardelago" : true, "CardUI" : self}

##Changes the cards parent and sets card slots
func shift_parent(nParent : Node):
	var parent = get_parent()
	if parent is CardSlot:
		parent.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.remove_child(self)
	nParent.add_child(self)
