extends Resource
class_name GameData

#AP Server Data
var apSaveData : SaveFile

#Dictionary Data
var gameCardsets : Dictionary[String, GameCardset]
var existingWords : Dictionary[String, NameFlags]
var fictionalWords : Dictionary[String, FictionalNameFlags]
var existingNames : Dictionary[String, NameData]
var allCards : Array[CardData]

##The Item Handler for AP data, including save data
var itemHandler : ItemHandler

func json_save() -> String:
	#Empty info
	var saveData : Dictionary = {
		"gameCardsets" : {},
		"existingWords" : {},
		"fictionalWords" : {},
		"existingNames" : {},
		"allCards" : [],
		"usedItems" : {}
	}
	if itemHandler != null:
		saveData["usedItems"] = itemHandler.json_save()
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
	gameData.itemHandler = ItemHandler.new()
	gameData.itemHandler.json_load(saveData["usedItems"])
	return gameData

func save_as_file(ip, port, slot, password):
	var otherFiles : int = 0
	var savePath := get_save_path()
	if DirAccess.dir_exists_absolute(savePath):
		var dir := DirAccess.open(savePath)
		for eachFile in dir.get_files():
			if eachFile.ends_with(".json"):
				otherFiles += 1
	else:
		DirAccess.make_dir_absolute(savePath)
	var saveFilePath : String = "%s/save%d.json" % [savePath, otherFiles]
	var saveFileString : String = json_save()
	var saveFileAccess := FileAccess.open(saveFilePath, FileAccess.WRITE)
	if saveFileAccess == null:
		print(saveFileAccess.get_error())
	apSaveData = SaveFile.new()
	apSaveData.aplock.lock(Archipelago.conn)
	apSaveData.creds.update(ip, port, slot, password)
	apSaveData.write(saveFileAccess)
	saveFileAccess.store_pascal_string(saveFileString)
	saveFileAccess.close()

static func find_valid_game(ip, port, slot, password) -> String:
	var savePath := get_save_path()
	if DirAccess.dir_exists_absolute(savePath):
		var dir := DirAccess.open(savePath)
		for eachFile in dir.get_files():
			if eachFile.ends_with(".json"):
				var checkSave = SaveFile.new()
				var filePath = savePath + "/" + eachFile
				var file := FileAccess.open(filePath, FileAccess.READ)
				if file == null:
					print(FileAccess.get_open_error())
					continue
				checkSave.read(file)
				if checkSave.aplock.valid:
					var lockNotifs : Array[String] = checkSave.aplock.lock(Archipelago.conn)
					for eachWarning in lockNotifs:
						print(eachWarning)
					if checkSave.creds.matches(ip, port, slot, password) and lockNotifs.size() <= 0:
						var output = file.get_pascal_string()
						file.close()
						return output
				file.close()
	else:
		DirAccess.make_dir_absolute(savePath)
	return ""

static func get_save_path() -> String:
	var baseDir = OS.get_executable_path().get_base_dir()
	if OS.has_feature("editor"):
		baseDir = "res://"
	return baseDir + "saves"
