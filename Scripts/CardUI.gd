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
var compressedCardData : Array[CardData]

func build(nCardData : CardData):
	cardData = nCardData
	if cardData.isDefault:
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
	for altCards in compressedCardData:
		apIds.append(altCards.apId)
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
	allPlayerNames.append(cardData.playerName)
	for eachName in compressedCardData:
		if !allPlayerNames.has(eachName.playerName):
			allPlayerNames.append(eachName.playerName)
	var playersNames : String = ", ".join(allPlayerNames).replace("[", "[lb]")
	uiCardGameLabel.text = "[center][color=black][i][u]%s[/u][/i][/color][color=%s]\n%s" % [cardData.gameCardset.game, PLAYER_NAME_COLOR, playersNames]
	uiCardGameLabel.do_resize_text()

##Show how many cards of this type you have
func update_card_count_display():
	if compressedCardData.size() > 0:
		uiCardCount.show()
		uiCardCount.text = str(compressedCardData.size() + 1)
	else:
		uiCardCount.hide()

func set_min_from_height(inHeight : int):
	custom_minimum_size = Vector2(ceili(inHeight * ratio), inHeight)

##Tries to combine cards into eachother for visual clarity
func try_compress_card(inCard : CardData) -> bool:
	if !inCard.is_comparable(cardData):
		return false
	compressedCardData.append(inCard)
	update_region_band()
	update_players_display()
	update_card_count_display()
	return true
