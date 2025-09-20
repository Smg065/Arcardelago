extends Resource
class_name GameData

#AP Server Data
var difficulty : int
var apSaveData : SaveFile

#Dictionary Data
var gameCardsets : Dictionary[String, GameCardset]
var existingWords : Dictionary[String, NameFlags]
var fictionalWords : Dictionary[String, FictionalNameFlags]
var existingNames : Dictionary[String, NameData]
var allCards : Array[CardData]

func json_save() -> String:
	#Empty info
	var saveData : Dictionary = {
		"difficulty" : difficulty,
		"gameCardsets" : {},
		"existingWords" : {},
		"fictionalWords" : {},
		"existingNames" : {},
		"allCards" : []
	}
	#Get each resources save info
	for eachGameCardset in gameCardsets:
		saveData["gameCardsets"][eachGameCardset] = gameCardsets[eachGameCardset].json_save()
	for eachExistingWord in existingWords:
		saveData["existingWords"][eachExistingWord] = existingWords[eachExistingWord].json_save()
	for eachFictionalWord in fictionalWords:
		saveData["fictionalWords"][eachFictionalWord] = fictionalWords[eachFictionalWord].json_save()
	for eachExistingName in existingNames:
		saveData["existingNames"][eachExistingName] = existingNames[eachExistingName].json_save()
	for eachCard in allCards:
		saveData["allCards"].append(eachCard.json_save())
	#Return it as a JSON string
	return JSON.stringify(saveData, "\t")

static func json_load(saveString : String) -> GameData:
	var gameData := GameData.new()
	var saveData = JSON.parse_string(saveString)
	gameData.difficulty = saveData["difficulty"]
	#Get each resources save info
	for eachExistingWord in saveData["existingWords"]:
		gameData.existingWords[eachExistingWord] = NameFlags.json_load(saveData["existingWords"][eachExistingWord])
	for eachFictionalWord in saveData["fictionalWords"]:
		gameData.fictionalWords[eachFictionalWord] = FictionalNameFlags.json_load(saveData["fictionalWords"][eachFictionalWord], gameData)
	for eachExistingName in saveData["existingNames"]:
		gameData.existingNames[eachExistingName] = NameData.json_load(saveData["existingNames"][eachExistingName], gameData)
	for eachGameCardset in saveData["gameCardsets"]:
		gameData.gameCardsets[eachGameCardset] = GameCardset.json_load(saveData["gameCardsets"][eachGameCardset], gameData)
	for eachCard in saveData["allCards"]:
		gameData.allCards.append(CardData.json_load(eachCard, gameData))
	return gameData
