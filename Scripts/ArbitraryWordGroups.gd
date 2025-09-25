extends Resource
class_name ArbitraryWordGroups

@export var name : String
@export var table : Array[ColorWordData]

func color_score(targetColor : String, checkWord : String, multiWord : bool = false) -> float:
	if multiWord:
		for eachEntry in table:
			if eachEntry.word.to_lower() == checkWord.to_lower():
				return eachEntry.get_weight(targetColor)
	else:
		var outSum : float = 0
		for eachEntry in table:
			if checkWord.containsn(eachEntry.word):
				outSum += eachEntry.get_weight(targetColor)
		return outSum
	return 0

func save_json() -> Dictionary:
	var saveData : Dictionary = {
		"name" : name,
		"table" : []
	}
	for eachEntry in table:
		saveData["table"].append(eachEntry.save_json())
	return saveData

func load_json(saveData : Dictionary):
	name = saveData["name"]
	table.clear()
	for saveIndex in saveData["table"]:
		var newEntry = ColorWordData.new()
		newEntry.load_json(saveIndex)
		table.append(newEntry)
