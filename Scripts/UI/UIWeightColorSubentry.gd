extends SubEntry
class_name ColorWeightSubentryUI

@export var colorTogglePrefab : PackedScene
var buttons : Dictionary[String, TextureButton]

func create_colors(customColors : Array[ColorCatagory]):
	#Cleanup the old data
	for eachButton in buttons:
		buttons[eachButton].queue_free()
	buttons.clear()
	#Build the new colors
	var colorsToUse : Array[ColorCatagory] = []
	colorsToUse.append_array(ColorCatagory.BASE_COLORS)
	colorsToUse.append_array(customColors)
	for eachColor in colorsToUse:
		var newButton : TextureButton = colorTogglePrefab.instantiate()
		newButton.connect("toggled", color_toggled.bind(newButton))
		newButton.tooltip_text = eachColor.name
		newButton.modulate = eachColor.color
		add_child(newButton)
		move_child(newButton, get_child_count() - 3)
		buttons[eachColor.name] = newButton

func weight_slider_changed(value: float) -> void:
	$SliderControl/WeightDisplay.text = "%1.2f" % value

func color_toggled(newState : bool, button : TextureButton):
	if newState:
		button.self_modulate = Color.WHITE
	else:
		button.self_modulate = Color(1,1,1,.25)

func to_color_weight() -> ColorWeights:
	var newWeights = ColorWeights.new()
	newWeights.weight = $SliderControl/WeightSlider.value
	for eachKey in buttons:
		if !buttons[eachKey].button_pressed:
			continue
		if ColorCatagory.ColorTypes.keys().has(eachKey.to_upper()):
			var index := ColorCatagory.ColorTypes.keys().find(eachKey.to_upper())
			newWeights.baseColors.append(ColorCatagory.ColorTypes[ColorCatagory.ColorTypes.keys()[index]])
		else:
			newWeights.customColors.append(eachKey)
	return newWeights

func from_color_weight(inWeight : ColorWeights, customColors : Array[ColorCatagory]) -> void:
	$SliderControl/WeightSlider.value = inWeight.weight
	create_colors(customColors)
	for eachBase in inWeight.baseColors:
		buttons[ColorCatagory.BASE_COLORS[eachBase].name].button_pressed = true
	for eachCustom in inWeight.customColors:
		buttons[eachCustom].button_pressed = true
	weight_slider_changed(inWeight.weight)
