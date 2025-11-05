extends GameScreen

@export var videoPlayer : VideoStreamPlayer
@export var backdrop : TextureRect
@export var cutsceneTable : Dictionary[String, VideoStream]
@export var backdropTable : Dictionary[String, Texture2D]

##Sets if this screen is active in the map viewer or not
func set_active(nState : bool, nInfo : Dictionary):
	var gameRoot : GameRoot = get_parent()
	super(nState, nInfo)
	if nState == false:
		return
	match nInfo["Type"]:
		"Gate":
			var regionNumber : int = nInfo["Region"]
			var colorNumber : int = nInfo["Color"]
			var colorName : String
			var canOpen : String
			if colorNumber == 0:
				colorName = "White"
				if true:
					canOpen = "Open"
				else:
					canOpen = "Locked"
			else:
				colorName = ColorCatagory.COLOR_NAMES[colorNumber - 1]
				if Persist.game.itemHandler.use_item("%s Sphere" % colorName, true):
					canOpen = "Open"
				else:
					canOpen = "Locked"
			if canOpen == "Open":
				gameRoot.clear_map_pip()
			set_backdrop("Feild %s" % regionNumber)
			start_cutscene("Gate %s %s" % [colorName, canOpen])
		_:
			cutscene_over()

##Start a cutscene of the given name
func start_cutscene(cutsceneName : String) -> void:
	if cutsceneTable.has(cutsceneName):
		videoPlayer.stream = cutsceneTable[cutsceneName]
		videoPlayer.play()
	else:
		push_warning("No cutscene named %s." % cutsceneName)
		cutscene_over()

##Set a background with the given name
func set_backdrop(backdropName : String) -> void:
	if backdropTable.has(backdropName):
		backdropTable.texture = backdropTable[backdropName]
	else:
		push_warning("No backdrop named %s." % backdropName)

##End the cutscene
func cutscene_over() -> void:
	var gameRoot : GameRoot = get_parent()
	gameRoot.switch_scenes()
