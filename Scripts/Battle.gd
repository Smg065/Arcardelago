extends GameScreen
class_name Battle

##Card Data with the times it square stacks
class EncounterSlot:
	var cardData : CardData
	var toStack : int = 1
	var slotIndex : int = 0
	func _init(nCardData : CardData, nSlotIndex : int) -> void:
		cardData = nCardData
		slotIndex = nSlotIndex

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
var currentEnemySlots : Array[CardSlot]

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
	if visible:
		if nInfo.has("Info"):
			setup_battle(nInfo["Info"])
		else:
			push_error("No Battle Data")
	else:
		clear_board()

##Relay the battle information
func setup_battle(nBattleInfo : BattleInfo):
	battleInfo = nBattleInfo
	#Graphical Updates
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
		#Get all card slots under it
		if layouts[eachLayout].visible:
			currentEnemySlots.clear()
			recursive_enemy_slot_search(layouts[eachLayout])
	#Enemy Construction
	update_valid_enemies()
	var battleEnemies := choose_enemy_cards()
	setup_feild(battleEnemies)

func recursive_enemy_slot_search(currentNode : Node):
	for eachChild in currentNode.get_children():
		if eachChild is CardSlot:
			currentEnemySlots.append(eachChild)
		else:
			recursive_enemy_slot_search(eachChild)

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

##Remove stuff
func clear_board():
	for eachEnemySlot in currentEnemySlots:
		eachEnemySlot.release_card()

##Place the cards down based on the encounter slot info
func setup_feild(battleEnemies : Array[EncounterSlot]):
	for eachEnemy in battleEnemies.size():
		var eachEnemySlot : CardSlot = currentEnemySlots[battleEnemies[eachEnemy].slotIndex]
		var enemyCard : CardUI = eachEnemySlot.cardPrefab.instantiate()
		eachEnemySlot.add_child(enemyCard)
		eachEnemySlot.setup_card(enemyCard)
		enemyCard.build(battleEnemies[eachEnemy].cardData)
		var extraEntries : int = int(pow(2, battleEnemies[eachEnemy].toStack - 1)) - 1
		for eachDataDupe in extraEntries:
			enemyCard.compressedCardData.append(battleEnemies[eachEnemy].cardData)
		enemyCard.new_compression_size()
		enemyCard.update_compressed_vis()

##Builds an array of enemies to battle
func choose_enemy_cards() -> Array[EncounterSlot]:
	var output : Array[EncounterSlot]
	var pointsRemaining = battleInfo.difficulty
	var table : Dictionary[int, Array]
	var openSlots : Array[int] = []
	openSlots.append_array(range(currentEnemySlots.size()))
	match battleInfo.type:
		BattleInfo.BattleType.BOSS:
			#Find the boss for this region
			for eachCard in Persist.game.allCards:
				if !eachCard.enemyCard:
					continue
				if eachCard.apItemFlags != 3:
					continue
				@warning_ignore("integer_division")
				var bossColor = (eachCard.apId - 6500000) / 10000
				print(eachCard.apId)
				print(bossColor)
				if battleInfo.region != bossColor:
					continue
				#Found the boss card!
				output.append(EncounterSlot.new(eachCard, 0))
				openSlots.erase(0)
				break
			#Scale it to the difficulty
			@warning_ignore("integer_division")
			var bossMulti = pointsRemaining / 30
			output[0].toStack = max(bossMulti, 1)
			pointsRemaining = pointsRemaining % 30
		BattleInfo.BattleType.FINAL_BOSS:
			print("Final Boss")
	for eachEnemy in validEnemies:
		table = PD.append_dict_entry(table, eachEnemy.powerScore, eachEnemy)
	#Fill Out Encounter
	if table.size() > 0:
		while pointsRemaining > 0:
			var entryKey = 0
			#Pick random while you don't have the points remaining as a key
			if !table.keys().has(pointsRemaining) and openSlots.size() != 1:
				entryKey = table.keys().pick_random()
			else:
				entryKey = pointsRemaining
			pointsRemaining -= entryKey
			var nextSlot : int = openSlots.pick_random()
			openSlots.erase(nextSlot)
			output.append(EncounterSlot.new(table[entryKey].pick_random(), nextSlot))
			var invalidKeys : Array[int] = []
			for eachEntry in table.keys():
				if eachEntry > pointsRemaining:
					invalidKeys.append(eachEntry)
			for eachEntry in invalidKeys:
				table.erase(eachEntry)
			##If there's 1 card left, only let exact matches be the last one filled
			var canExactFill := (openSlots.size() > 1 or table.keys().has(pointsRemaining))
			if !canExactFill or openSlots.size() <= 0 or table.size() <= 0:
				break
	#Stacking with Leftover Points
	if pointsRemaining > 0:
		var stackTable : Dictionary[int, Array]
		for eachEnemy in output:
			var stackBonus = (eachEnemy.cardData.baseAttack + eachEnemy.cardData.baseHealth)
			if stackBonus > pointsRemaining:
				continue
			stackTable = PD.append_dict_entry(stackTable, stackBonus, eachEnemy)
		if stackTable.size() > 0:
			while pointsRemaining > 0:
				var entryKey : int = stackTable.keys().pick_random()
				pointsRemaining -= entryKey
				stackTable[entryKey].pick_random().toStack += 1
				var toDelete : Array[int]
				for eachKey in stackTable.keys():
					if eachKey > pointsRemaining:
						continue
					toDelete.append(eachKey)
				for eachDeletion in toDelete:
					stackTable.erase(eachDeletion)
				#As long as there's stackable enemies, stack them
				if stackTable.size() <= 0:
					break
	#Fallback if there's nothing valid to add to output
	if output.size() == 0 and validEnemies.size() > 0:
		var nextSlot : int = openSlots.pick_random()
		openSlots.erase(nextSlot)
		var fallbackCard := EncounterSlot.new(validEnemies.pick_random(), nextSlot)
		fallbackCard.toStack = pointsRemaining
		output.append(fallbackCard)
	#Default cards
	if openSlots.size() > 0 and pointsRemaining > 0:
		var nextSlot : int = openSlots.pick_random()
		openSlots.erase(nextSlot)
		var defaultFilling := EncounterSlot.new(CardData.new_default(true), nextSlot)
		defaultFilling.toStack = pointsRemaining
		output.append(defaultFilling)
	return output

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
		#Bosses should not be random enemy encounters
		if eachCard.apItemFlags == 3:
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
