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
@export var playerPip : Texture2D
@export var enemyPip : Texture2D
@export var bossPip : Texture2D

var cardData : CardData

func build(nCardData : CardData):
	cardData = nCardData
	uiCardBackColor.colors = cardData.colors
	uiCardPipColor.colors = cardData.colors
	uiCardSetPipColor.colors = cardData.gameCardset.setColor
	uiCardSetPipColor.build(playerPip)
	uiCardBackColor.build(cardData.fadeAngle)
	if cardData.enemyCard:
		if cardData.apItemFlags == 3:
			uiCardPipColor.build(bossPip)
		else:
			uiCardPipColor.build(enemyPip)
	else:
		uiCardPipColor.build(playerPip)
	update_rich_texts()

func update_rich_texts():
	uiCardNameLabel.text = "[center][bgcolor=snow][color=black]" + cardData.nameData.name
	uiCardItemFlagLabel.text = "[center]" + cardData.rich_item_flags()
	uiCardWordTypesLabel.text = "[center][bgcolor=snow][color=black]" + "/".join(cardData.unique_parts_of_speech())
	uiCardPhoneticsLabel.text = "[center][bgcolor=slategray]" + ", ".join(cardData.rich_phonetic_symbols())
	uiCardGameLabel.text = "[center][i][u][color=black]" + cardData.gameCardset.game + " - (" + cardData.playerName.replace("[", "[lb]") + ")"
	uiCardNameLabel.do_resize_text()
	uiCardItemFlagLabel.do_resize_text()
	uiCardWordTypesLabel.do_resize_text()
	uiCardPhoneticsLabel.do_resize_text()
	uiCardGameLabel.do_resize_text()
