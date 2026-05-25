extends Resource
class_name GameData

#AP Server Data
var apSaveData : SaveFile

#Dictionary Data
var gameCardsets : Dictionary[String, GameCardset]
var existingWords : Dictionary[String, NameFlags]
var fictionalWords : Dictionary[String, FictionalNameFlags]
var existingNames : Dictionary[String, NameData]
##All cards that exist in this game
var allCards : Array[CardData]
##Locations that have been scouted this game
var knownLoctions : PackedInt32Array
##Regions where the boss was defeated
var defeatedBosses : Array[int]
signal defeated_bosses_updated

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

func save_as_file():
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
	apSaveData.creds.update(Persist.ip, Persist.port, Persist.slot, Persist.password)
	apSaveData.write(saveFileAccess)
	saveFileAccess.store_pascal_string(saveFileString)
	saveFileAccess.close()

static func get_all_save_files() -> Array[SaveFile]:
	var allSaveFiles : Array[SaveFile] = []
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
				allSaveFiles.append(checkSave)
				file.close()
	return allSaveFiles

static func find_valid_game() -> String:
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
				#Make sure there's enough slots to check
				if Archipelago.conn.slots.size() < checkSave.aplock.player_id:
					continue
				#Check if the aplock is valid
				if checkSave.aplock.valid:
					var lockNotifs : Array[String] = checkSave.aplock.lock(Archipelago.conn)
					for eachWarning in lockNotifs:
						print(eachWarning)
					if checkSave.creds.matches(Persist.ip, Persist.port, Persist.slot, Persist.password) and lockNotifs.size() <= 0:
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

##Get all regions you have reached so far
func reached_regions() -> PackedStringArray:
	var output : PackedStringArray
	#Determine the card pools that are unlocked.
	for colorName in ColorCatagory.COLOR_NAMES:
		var requiredRegions = PD.get_graph_path(Persist.worldOrder, Persist.spawnName, colorName)
		var pathCompletable : bool = true
		for eachRequired in requiredRegions:
			if !itemHandler.usedItems.items.has(eachRequired + " Sphere") and !Persist.spawnName == eachRequired:
				pathCompletable = false
				break
		if pathCompletable:
			output.append(colorName)
	return output

##The card pool used to fetch new cards
func current_cardpool() -> Array[CardData]:
	var reachedRegions := reached_regions()
	var currentCardpool : Array[CardData] = []
	#Go over all cards in your game
	for eachCard in allCards:
		#Enemies and defaults don't count
		if eachCard.enemyCard or eachCard.isDefault:
			continue
		#No duplicates
		if Persist.currentCards.has(eachCard):
			continue
		@warning_ignore("integer_division")
		var regionColor : int = floori((eachCard.apId - 65000.0) / 100.0)
		#Must have reached that region at least once
		if !reachedRegions.has(ColorCatagory.COLOR_NAMES[regionColor]):
			continue
		#Must not have released this item
		if Archipelago.conn.slot_locations[eachCard.apId]:
			#If you have, it must be ghost stamped
			if !eachCard.stamps.has("Ghost"):
				continue
		#It must be in the current cardpool
		currentCardpool.append(eachCard)
	return currentCardpool

##Scout for a card you haven't seen yet.
func scout_unknown():
	##A list of all cards you have not come across yet
	var unknownCards : Array[CardData]
	for eachCard in allCards:
		#This is just a hint, don't do that
		if eachCard.enemyCard:
			continue
		#But cards you don't know but can scout are fair game
		if knownLoctions.has(eachCard.apId):
			continue
		unknownCards.append(eachCard)
	##Prioritize Non-Cardpool cards if possible first.
	var priorityUnknowns : Array[CardData] = unknownCards.duplicate()
	for inCardpool in current_cardpool():
		priorityUnknowns.erase(inCardpool)
	var toScout : CardData = null
	if priorityUnknowns.size() > 0:
		toScout = priorityUnknowns.pick_random()
	elif unknownCards.size() > 0:
		toScout = unknownCards.pick_random()
	if toScout != null:
		toScout.scout()
	else:
		Persist.game.itemHandler.increase_overscouts()

##When youi defeat a boss of a region
func defeated_boss(region : int):
	if region in defeatedBosses:
		return
	defeatedBosses.append(region)
	defeated_bosses_updated.emit()
