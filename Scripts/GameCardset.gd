extends Resource
class_name GameCardset

var game : String
var players : PackedStringArray
var nameData : NameData
var playerCards : Array[CardData]
var enemyCards : Array[CardData]

static func build(newData : NameData) -> GameCardset:
	var newCardset := GameCardset.new()
	newCardset.game = newData.name
	newCardset.nameData = newData
	return newCardset

func json_save() -> Dictionary:
	var saveOutput : Dictionary = {
		"game" : game,
		"players" : players
	}
	return saveOutput

static func json_load(inDict, gameData : GameData) -> GameCardset:
	var newCardset := GameCardset.new()
	newCardset.game = inDict["game"]
	newCardset.players = inDict["players"]
	newCardset.nameData = gameData.existingNames[newCardset.game]
	return newCardset
