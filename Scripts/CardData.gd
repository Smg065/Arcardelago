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
