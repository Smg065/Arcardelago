extends Node
class_name CardSignalManager

##When the an Arcardelago battle starts up
signal battle_start
##When a card attacks another card
signal attack
##When a card is defeated
signal defeat


## 
var signalTable : Dictionary[String, Signal] = {
	"Battle Start" : battle_start,
	"Attack" : attack,
	"Defeat" : defeat
}
