extends Node
class_name CardData

var playerName : String
var gameName : String

func _init(apItem : NetworkItem):
	var player : NetworkPlayer = Archipelago.conn.get_player(apItem.dest_player_id)
	playerName = player.get_name()
	gameName = player.get_slot().game
	apItem.get_classification()
