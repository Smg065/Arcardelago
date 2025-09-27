extends Resource
class_name GameCardset

var game : String
var players : PackedStringArray
var nameData : NameData
var playerCards : Array[CardData]
var enemyCards : Array[CardData]
var colorScore : Dictionary[ColorCatagory.ColorTypes, float]
var setColor : int

static func build(newData : NameData) -> GameCardset:
	var newCardset := GameCardset.new()
	newCardset.game = newData.name
	newCardset.nameData = newData
	newCardset.get_set_scores()
	return newCardset

func get_set_scores():
	for baseColor in ColorCatagory.BASE_COLORS:
		var colorType : ColorCatagory.ColorTypes = baseColor.colorType
		colorScore[colorType] = 0
		for eachFlag in nameData.nameFlags:
			colorScore[colorType] += eachFlag.get_score(baseColor)
	setColor = CardData.scores_to_color(colorScore, .33333)

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
	newCardset.get_set_scores()
	return newCardset
