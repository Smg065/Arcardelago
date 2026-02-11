extends Node
class_name GameRoot

@export var screenNodes : Dictionary[ScreenType, GameScreen]
@export var boosterPack : BoosterPackUI
@export var scrollBox : CardScrollbox

var curScreen : ScreenType = ScreenType.HOME

enum ScreenType {WORLD_MAP, CUTSCENE, BATTLE, EVENT, SHOP, TREASURE, RELEASER, HOME}

func _ready() -> void:
	switch_scenes(ScreenType.HOME, {"Region" : 1 + int(Persist.spawnSphere)})

func switch_scenes(newScreen : ScreenType = ScreenType.WORLD_MAP, info : Dictionary = { }):
	screenNodes[curScreen].set_active(false, {})
	curScreen = newScreen
	screenNodes[curScreen].set_active(true, info)

##Marks the node the player is at as clear on the map
func clear_map_pip():
	screenNodes[ScreenType.WORLD_MAP].player_clear_node()

##Gets the node the player is at
func get_map_pip() -> MapPip:
	return screenNodes[ScreenType.WORLD_MAP].mapPlayer.curPip

##Lose a life
func die() -> void:
	#Full game over (inventory clear and house reset)
	if not Persist.game.itemHandler.lose_life():
		Persist.clear_cards()
		screenNodes[ScreenType.HOME].highestLevelReward = 0
	#Call for a map reset
	screenNodes[ScreenType.WORLD_MAP].reset()
	#Go home
	switch_scenes(ScreenType.HOME, screenNodes[ScreenType.WORLD_MAP].homePip.nodeInfo)
