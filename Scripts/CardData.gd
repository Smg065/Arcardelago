extends Node
class_name CardData

var playerName : String
var gameName : String
var nameData : NameData
var apId : int
var externalCard : bool

func _init(apItem : NetworkItem, newApId : int, newData : NameData, newGameName : String, newPlayer : String, newExternalCard : bool = false):
	playerName = newPlayer
	apId = newApId
	gameName = newGameName
	nameData = newData
	externalCard = newExternalCard
	apItem.get_classification()
	print("Game " + newGameName + " Player " + playerName + ", " + str(apId) + ": " + nameData.name)
