extends Resource
class_name ColorWordData

@export var word : String
@export var colorWeights : Array[ColorWeights]

func get_weight(targetColor : String) -> float:
	var colorCat : ColorCatagory.ColorTypes
	match targetColor:
		"Red":
			colorCat = ColorCatagory.RED
		"Green":
			colorCat = ColorCatagory.GREEN
		"Violet":
			colorCat = ColorCatagory.VIOLET
		"Orange":
			colorCat = ColorCatagory.ORANGE
		"Blue":
			colorCat = ColorCatagory.BLUE
		"Yellow":
			colorCat = ColorCatagory.YELLOW
		_:
			colorCat = ColorCatagory.ColorTypes.CUSTOM
	for eachWeight in colorWeights:
		if colorCat != ColorCatagory.ColorTypes.CUSTOM:
			if eachWeight.baseColors.has(colorCat):
				return eachWeight.weight
		elif eachWeight.customColors.has(targetColor):
				return eachWeight.weight
	return 0

func save_json() -> Dictionary:
	var saveData : Dictionary = {
		"word" = word
	}
	for eachIndex in colorWeights.size():
		saveData[eachIndex] = colorWeights[eachIndex].save_json()
	return saveData

func load_json(saveData : Dictionary) -> void:
	word = saveData["word"]
	colorWeights.clear()
	colorWeights.resize(saveData.size() - 1)
	for eachIndex in colorWeights.size():
		colorWeights[eachIndex] = ColorWeights.new()
		colorWeights[eachIndex].load_json(saveData[str(eachIndex)])
