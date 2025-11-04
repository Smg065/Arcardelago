extends Node
class_name GameRoot

@export var screenNodes : Dictionary[ScreenType, GameScreen]
@export var boosterPack : BoosterPackUI

var curScreen : ScreenType = ScreenType.WORLD_MAP

enum ScreenType {WORLD_MAP, CUTSCENE, BATTLE, EVENT, SHOP, TREASURE, RELEASER, HOME}

func switch_scenes(newScreen : ScreenType = ScreenType.WORLD_MAP, info : Dictionary = { }):
	screenNodes[curScreen].set_active(false, {})
	curScreen = newScreen
	screenNodes[curScreen].set_active(true, info)
