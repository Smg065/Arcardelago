extends Resource
class_name GameCardset

var game : String
var nameData : NameData
var playerCards : Array[CardData]
var enemyCards : Array[CardData]

func _init(newData : NameData) -> void:
	game = newData.name
	nameData = newData
