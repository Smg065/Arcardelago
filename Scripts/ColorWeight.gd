extends Resource
class_name ColorWeights

@export_range(-1, 1) var weight : float
@export var baseColors : Array[ColorCatagory.ColorTypes]
@export var customColors : PackedStringArray

func save_json() -> Dictionary:
	var saveData : Dictionary = {
		"weight" : weight,
		"baseColors" : [],
		"customColors" : customColors
	}
	for eachBase in baseColors:
		saveData["baseColors"].append(ColorCatagory.ColorTypes.values().find(eachBase))
	return saveData

func load_json(saveData : Dictionary) -> void:
	weight = saveData["weight"]
	for eachEntry in saveData["baseColors"]:
		baseColors.append(int(eachEntry))
	customColors = saveData["customColors"]
