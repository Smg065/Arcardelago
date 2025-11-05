extends GameScreen
class_name Home

func _ready() -> void:
	var gameRoot : GameRoot = get_parent()
	gameRoot.boosterPack.setup()

func exit_house():
	var gameRoot : GameRoot = get_parent()
	gameRoot.switch_scenes()
