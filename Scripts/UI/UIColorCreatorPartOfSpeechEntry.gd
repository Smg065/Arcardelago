extends Control
class_name PartOfSpeechEntryUI

@export var partName : String

func _ready() -> void:
	$POSToggle.button_text = partName

func toggled(toggled_on: bool) -> void:
	if toggled_on:
		$POSScore.show()
	else:
		$POSScore.hide()

func get_value() -> float:
	if $POSToggle.button_pressed:
		return $POSScore.value
	return 0

func set_enabled(newPressed : bool):
	$POSToggle.button_pressed = newPressed
	toggled(newPressed)

func set_value(newVal : float):
	$POSScore.value = newVal
