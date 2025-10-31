extends GameScreen
class_name Battle

##If the mouse is over the battlefield
var mouseFocused : bool
var draggingMap : bool
var mouseStartPoint : Vector2
var mapStartPoint : Vector2

##The info needed to setup the battle.
@export var battleInfo : BattleInfo
##The mat where the cards are all displayed
@export var battlemap : AspectRatioContainer
##The scrollbox containing the displayed card info
@export var battleScroll : ScrollContainer

@export_category("Enemy Feild")
@export var layouts : Array[Node]
var validEnemies : Array[CardData]

@export_category("Background Visuals")
##The background of the screen
@export var battleBackground : TextureRect
##The options the background would use
@export var battleBackgrounds : Array[Texture2D]

##The zoom of the map. Range from 0-20
var zoomVal : int

##Set the battle map as active
func set_active(nState : bool, nInfo : Dictionary):
	visible = nState
	if nInfo.has("Info"):
		setup_battle(nInfo["Info"])
	else:
		push_error("No Battle Data")

##Relay the battle information
func setup_battle(nBattleInfo : BattleInfo):
	battleInfo = nBattleInfo
	battleBackground.texture = battleBackgrounds[battleInfo.region]
	var toEnable = 0
	match battleInfo.type:
		BattleInfo.BattleType.DEFAULT:
			toEnable = 0
		BattleInfo.BattleType.RIVAL:
			toEnable = 1
		BattleInfo.BattleType.BOSS:
			toEnable = 2
		BattleInfo.BattleType.FINAL_BOSS:
			toEnable = 3
	for eachLayout in layouts.size():
		layouts[eachLayout].visible = eachLayout == toEnable
	update_valid_enemies()

func _input(event: InputEvent) -> void:
	if !mouseFocused and !draggingMap:
		return
	if event is InputEventMouse:
		battlemap.pivot_offset = event.global_position - battlemap.global_position
	if event is InputEventMouseButton:
		if event.is_pressed() and !event.shift_pressed:
			match event.button_index:
				MouseButton.MOUSE_BUTTON_WHEEL_UP:
					change_zoom(1)
					get_viewport().set_input_as_handled()
				MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
					change_zoom(-1)
					get_viewport().set_input_as_handled()
				MouseButton.MOUSE_BUTTON_LEFT:
					draggingMap = true
		if event.is_released():
			match event.button_index:
				MouseButton.MOUSE_BUTTON_LEFT:
					draggingMap = false
	if event is InputEventMouseMotion:
		if draggingMap:
			battlemap.global_position += event.relative

##Use the batlte info to update what enemies are allowed to show up
func update_valid_enemies():
	validEnemies.clear()
	#Filter to the cards you need for this battle
	for eachCard in Persist.game.allCards:
		#Enemy Cards
		if !eachCard.enemyCard:
			continue
		#Of the right difficulty
		if battleInfo.difficulty < eachCard.powerScore:
			continue
		@warning_ignore("integer_division")
		var enemyColor : int = (eachCard.apId - 6500000) / 10000
		##Enemies that have an item of that color
		var idColorMatch : bool = battleInfo.region == 0 or enemyColor == 0 or enemyColor == battleInfo.region
		##Enemies that are part of this color set/are colorless
		var cardColorMatch : bool = battleInfo.region == 0 or eachCard.colors == 0 or eachCard.colors & (2 ** (battleInfo.region - 1))
		#Only one of the 2 kinds of colors need to match up
		if !idColorMatch and !cardColorMatch:
			continue
		validEnemies.append(eachCard)

##Zooming in and out
func change_zoom(zoomDir : int):
	zoomVal = clampi(zoomVal + zoomDir, 0, 25)
	var screenSize := get_viewport().get_visible_rect().size
	var smallerAxis : float = min(screenSize.x, screenSize.y)
	var minZoom := floori(sqrt(smallerAxis))
	battlemap.custom_minimum_size = Vector2.ONE * pow(minZoom + zoomVal, 2)
	battlemap.size = battlemap.custom_minimum_size

##Needed to start mouse events
func mouse_on_battlefield() -> void:
	mouseFocused = true

##Needed to stop mouse events
func mouse_off_battlefield() -> void:
	mouseFocused = false
