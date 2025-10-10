extends Node
class_name GameRoot

@export var screenNodes : Dictionary[ScreenType, GameScreen]

var curScreen : ScreenType = ScreenType.WORLD_MAP

enum ScreenType {WORLD_MAP, CUTSCENE, BATTLE, EVENT, SHOP, TREASURE, RELEASER, HOME}

func switch_scenes(newScreen : ScreenType = ScreenType.WORLD_MAP):
	screenNodes[curScreen].set_active(false)
	curScreen = newScreen
	screenNodes[curScreen].set_active(true)
