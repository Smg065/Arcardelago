extends Resource
class_name CardData

var playerName : String
var gameCardset : GameCardset
var nameData : NameData
var apId : int
var apItemFlags : int
var enemyCard : bool
var fadeAngle : float
var isLocal : bool

@export_flags("Red", "Green", "Violet", "Orange", "Blue", "Yellow") var colors : int = 0

const RED = ColorCatagory.ColorTypes.RED
const GREEN = ColorCatagory.ColorTypes.GREEN
const VIOLET = ColorCatagory.ColorTypes.VIOLET
const ORANGE = ColorCatagory.ColorTypes.ORANGE
const BLUE = ColorCatagory.ColorTypes.BLUE
const YELLOW = ColorCatagory.ColorTypes.YELLOW

static func build(newApItemFlags : int, newApId : int, newData : NameData, newGameCardset : GameCardset, newPlayer : String, newIsLocal : bool, newEnemyCard : bool = false) -> CardData:
	var cardData := CardData.new()
	cardData.playerName = newPlayer
	cardData.apId = newApId
	cardData.gameCardset = newGameCardset
	cardData.nameData = newData
	cardData.enemyCard = newEnemyCard
	cardData.apItemFlags = newApItemFlags
	cardData.fadeAngle = randf_range(0, 2*PI)
	cardData.isLocal = newIsLocal
	#Enemy cards are the locations of your items
	if cardData.enemyCard:
		cardData.gameCardset.enemyCards.append(cardData)
	#Player cards are your items
	else:
		cardData.gameCardset.playerCards.append(cardData)
	cardData.colors = cardData.calculate_color()
	return cardData

func json_save():
	var saveOutput : Dictionary = {
		"playerName" : playerName,
		"apId" : apId,
		"nameData" : nameData.name,
		"apItemFlags" : apItemFlags,
		"enemyCard" : enemyCard,
		"fadeAngle" : fadeAngle,
		"isLocal" : isLocal
	}
	return saveOutput

static func json_load(inDict, gameData : GameData) -> CardData:
	var cardData := CardData.new()
	cardData.playerName = inDict["playerName"]
	cardData.apId = inDict["apId"]
	cardData.apItemFlags = inDict["apItemFlags"]
	cardData.enemyCard = inDict["enemyCard"]
	cardData.fadeAngle = inDict["fadeAngle"]
	cardData.isLocal = inDict["isLocal"]
	cardData.nameData = gameData.existingNames[inDict["nameData"]]
	for eachGame in gameData.gameCardsets:
		if gameData.gameCardsets[eachGame].players.has(cardData.playerName):
			cardData.gameCardset = gameData.gameCardsets[eachGame]
			if cardData.enemyCard:
				gameData.gameCardsets[eachGame].enemyCards.append(cardData)
			else:
				gameData.gameCardsets[eachGame].playerCards.append(cardData)
				break
	cardData.colors = cardData.calculate_color()
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

func calculate_color() -> int:
	var colorScore : Dictionary[ColorCatagory.ColorTypes, float] = {}
	for baseColor in ColorCatagory.BASE_COLORS:
		#Oh sweet lordy
		var colorType : ColorCatagory.ColorTypes = baseColor.colorType
		colorScore[colorType] = 0
		#Source Pref Flags
		match baseColor.itemSourcePref:
			ColorCatagory.SourcePref.LOCAL:
				if isLocal:
					colorScore[colorType] += ColorCatagory.MULTI_SOURCE
			ColorCatagory.SourcePref.EXTERNAL:
				if not isLocal:
					colorScore[colorType] += ColorCatagory.MULTI_SOURCE
		#Item Quality Flags
		if baseColor.itemQualityFlags.has(apItemFlags):
			colorScore[colorType] += ColorCatagory.MULTI_ITEM_FLAGS * baseColor.itemQualityMulti
		#Go over the name flags
		for eachFlag in nameData.nameFlags:
			colorScore[colorType] += eachFlag.get_score(baseColor)
	
	print(nameData.name + "," + ",".join(colorScore.values()))
	return randi_range(0, 63)
