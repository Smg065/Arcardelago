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

@export_flags("Red", "Green", "Violet", "Orange", "Blue", "Yellow") var colors : int = 0

const RED = ColorCatagory.ColorTypes.RED
const GREEN = ColorCatagory.ColorTypes.GREEN
const VIOLET = ColorCatagory.ColorTypes.VIOLET
const ORANGE = ColorCatagory.ColorTypes.ORANGE
const BLUE = ColorCatagory.ColorTypes.BLUE
const YELLOW = ColorCatagory.ColorTypes.YELLOW

var cardData : CardData

func _ready() -> void:
	colors = randi_range(0, 63)
	uiCardBackColor.colors = colors
	uiCardBackColor.build()
	uiCardPipColor.colors = colors
	uiCardPipColor.build()

func build(nCardData : CardData):
	cardData = nCardData
	update_rich_texts()

func update_rich_texts():
	uiCardNameLabel.text = "[center][bgcolor=snow][color=black]" + cardData.nameData.name
	uiCardItemFlagLabel.text = "[center]" + cardData.rich_item_flags()
	uiCardWordTypesLabel.text = "[center][bgcolor=snow][color=black]" + "/".join(cardData.unique_parts_of_speech())
	uiCardPhoneticsLabel.text = "[center][bgcolor=slategray]" + ", ".join(cardData.rich_phonetic_symbols())
	uiCardGameLabel.text = "[center][i][u][color=black]" + cardData.gameCardset.game + " - (" + cardData.playerName + ")"
	uiCardNameLabel.do_resize_text()
	uiCardItemFlagLabel.do_resize_text()
	uiCardWordTypesLabel.do_resize_text()
	uiCardPhoneticsLabel.do_resize_text()
	uiCardGameLabel.do_resize_text()
