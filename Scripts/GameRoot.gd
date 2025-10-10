extends Node
class_name GameRoot

@onready
var curScreen = %WorldMap

enum ScreenType {WORLD_MAP, CUTSCENE, BATTLE, EVENT, SHOP, TREASURE, RELEASER, HOME}

func switch_scenes(newScreen : ScreenType = ScreenType.WORLD_MAP):
	curScreen.set_active(false)
	match newScreen:
		ScreenType.WORLD_MAP:
			curScreen = %WorldMap
		ScreenType.BATTLE:
			curScreen = %Battlescreen
	curScreen.set_active(true)
