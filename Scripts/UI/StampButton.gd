extends Button
class_name StampButton

const STAMP_PATH = "res://Sprites/Items/Stamp"

var stampType : String
var cardUi : CardUI

##Create a new stamp button for cards
static func generate_button(nCardUi : CardUI, nStampType : String, stampCount : int) -> StampButton:
	var outButton := StampButton.new()
	outButton.cardUi = nCardUi
	outButton.stampType = nStampType
	outButton.tooltip_text = nStampType + " Stamp"
	outButton.flat = true
	outButton.icon = load(STAMP_PATH + outButton.stampType + ".png")
	outButton.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	outButton.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outButton.expand_icon = true
	outButton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	match outButton.stampType:
		"Steel":
			outButton.toggle_mode = true
		"Harmony":
			outButton.disabled = true
		"Ghost":
			outButton.disabled = true
		"Square":
			outButton.toggle_mode = true
		"Gold":
			outButton.pressed.connect(nCardUi.gold_stamp_release)
	if stampCount == 1:
		outButton.text = ""
	else:
		outButton.text = str(stampCount)
	return outButton
