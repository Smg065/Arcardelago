extends Node
class_name CardData

var playerName : String
var gameCardset : GameCardset
var nameData : NameData
var apId : int
var apItemFlags : int
var externalCard : bool

func _init(apItem : NetworkItem, newApId : int, newData : NameData, newGameCardset : GameCardset, newPlayer : String, newExternalCard : bool = false):
	playerName = newPlayer
	apId = newApId
	gameCardset = newGameCardset
	nameData = newData
	externalCard = newExternalCard
	apItemFlags = apItem.flags
	#Enemy cards are the locations of your items
	if externalCard:
		gameCardset.enemyCards.append(self)
	#Player cards are your items
	else:
		gameCardset.playerCards.append(self)
