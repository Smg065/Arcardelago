extends Resource
class_name CardData

var playerName : String
var gameCardset : GameCardset
var nameData : NameData
var apId : int
var apItemFlags : int
var enemyCard : bool

static func build(newApItemFlags : int, newApId : int, newData : NameData, newGameCardset : GameCardset, newPlayer : String, newEnemyCard : bool = false) -> CardData:
	var cardData := CardData.new()
	cardData.playerName = newPlayer
	cardData.apId = newApId
	cardData.gameCardset = newGameCardset
	cardData.nameData = newData
	cardData.enemyCard = newEnemyCard
	cardData.apItemFlags = newApItemFlags
	#Enemy cards are the locations of your items
	if cardData.enemyCard:
		cardData.gameCardset.enemyCards.append(cardData)
	#Player cards are your items
	else:
		cardData.gameCardset.playerCards.append(cardData)
	return cardData

func json_save():
	var saveOutput : Dictionary = {
		"playerName" : playerName,
		"apId" : apId,
		"nameData" : nameData.name,
		"apItemFlags" : apItemFlags,
		"enemyCard" : enemyCard
	}
	return saveOutput

static func json_load(inDict, gameData : GameData) -> CardData:
	var cardData := CardData.new()
	cardData.playerName = inDict["playerName"]
	cardData.apId = inDict["apId"]
	cardData.apItemFlags = inDict["apItemFlags"]
	cardData.enemyCard = inDict["enemyCard"]
	cardData.nameData = gameData.existingNames[inDict["nameData"]]
	for eachGame in gameData.gameCardsets:
		if gameData.gameCardsets[eachGame].players.has(cardData.playerName):
			cardData.gameCardset = gameData.gameCardsets[eachGame]
			if cardData.enemyCard:
				gameData.gameCardsets[eachGame].enemyCards.append(cardData)
			else:
				gameData.gameCardsets[eachGame].playerCards.append(cardData)
				break
	return cardData



func rich_item_flags() -> String:
	#Proguseful
	if apItemFlags == 3:
		return "[hint=An item that is critical for progression][bgcolor=GOLD][color=BLACK]Proguseful"
	#Trap
	elif apItemFlags >= 4:
		return "[hint=An item that actively hinders the owner][bgcolor=SALMON][color=BLACK]Trap"
	#Progression
	elif apItemFlags == 1:
		return "[hint=An item that can unlock checks][bgcolor=PLUM][color=BLACK]Progression"
	#Useful
	elif apItemFlags == 2:
		return "[hint=An item that while not required, is especially useful][bgcolor=SLATEBLUE][color=WHITE]Useful"
	#Filler
	return "[hint=An unimportant item][bgcolor=CYAN][color=BLACK]Filler"

func rich_phonetic_symbols() -> PackedStringArray:
	return nameData.rich_text_unique_phonetics()

func unique_parts_of_speech():
	var allParts = nameData.get_parts_of_speech()
	var uniqueDict : Dictionary[String, int] = {}
	for eachPart in allParts:
		if not uniqueDict.has(eachPart):
			uniqueDict[eachPart] = 1
		else:
			uniqueDict[eachPart] += 1
	var outString := PackedStringArray([])
	for eachUnique in uniqueDict:
		outString.append(eachUnique.capitalize() + " x" + str(uniqueDict[eachUnique]))
	return outString
