extends Node
class_name GameRoot

@export var screenNodes : Dictionary[ScreenType, GameScreen]
@export var boosterPack : BoosterPackUI

var curScreen : ScreenType = ScreenType.HOME

enum ScreenType {WORLD_MAP, CUTSCENE, BATTLE, EVENT, SHOP, TREASURE, RELEASER, HOME}

func switch_scenes(newScreen : ScreenType = ScreenType.WORLD_MAP, info : Dictionary = { }):
	screenNodes[curScreen].set_active(false, {})
	curScreen = newScreen
	screenNodes[curScreen].set_active(true, info)

##Marks the node the player is at as clear on the map
func clear_map_pip():
	screenNodes[ScreenType.WORLD_MAP].player_clear_node()
