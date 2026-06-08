extends GameScreen
class_name Home

##The current level of the house
var houseLevel : int
##The highest level you've claimed
var highestLevelReward : int
##The region your home is in
var region : int

@export var grounds : TextureRect
@export var buttons : Array[TextureButton]
@export var sleepButton : Button
@export var sleepTimer : Timer
@export var bossReleaseSlot : CardSlot
@export var bossReleaseButton : Button
@export var bossReleaseIcons : Array[TextureRect]
@export var bossReleaseTexture : Texture2D

func _ready() -> void:
	Persist.game.defeated_bosses_updated.connect(update_boss_release_textures)


##Updates the textures for the boss releasers
func update_boss_release_textures() -> void:
	for eachEntry in Persist.game.defeatedBosses:
		if eachEntry <= 0:
			continue
		bossReleaseIcons[eachEntry - 1].texture = bossReleaseTexture

func set_active(nState : bool, nInfo : Dictionary) -> void:
	if nState:
		region = nInfo["Region"]
		construct_house()
		claim_house_rewards()
	super(nState, nInfo)

##Update the total house level
func notify_house_level() -> void:
	var curInventory := Persist.game.itemHandler.current_inventory()
	houseLevel = curInventory.items.count("House Upgrade") + 1

##Construct the houses visuals
func construct_house():
	var colorCat := ColorCatagory.BASE_COLORS[region - 1]
	grounds.texture = colorCat.homeGround
	for buttonIndex in buttons.size():
		var eachButton := buttons[buttonIndex]
		match buttonIndex:
			0:
				setup_room(eachButton, colorCat.homeBedroom)
			1:
				setup_room(eachButton, colorCat.homeKitchen)
			2:
				setup_room(eachButton, colorCat.homeLobby)
			3:
				setup_room(eachButton, colorCat.homeWorkspace)

##Sets up the button's layer to either be usable or not
func setup_room(inButton : TextureButton, roomInfo : HomeStructure):
	inButton.tooltip_text = roomInfo.name
	var texToUse
	if roomInfo.unlocks > houseLevel:
		inButton.disabled = true
		texToUse = roomInfo.missingArea
	else:
		inButton.disabled = false
		texToUse = roomInfo.builtArea
	inButton.texture_normal = texToUse
	var clickMask := BitMap.new()
	clickMask.create_from_image_alpha(texToUse.get_image())
	inButton.texture_click_mask = clickMask

##Get all rewards up to the date
func claim_house_rewards() -> void:
	notify_house_level()
	#10 gold if it's a new start
	if highestLevelReward == 0:
		var toEarn = 10 - (Persist.difficulty * 5)
		if toEarn > 0:
			Persist.game.itemHandler.earn(toEarn, {"Type" : "House"})
	while highestLevelReward < houseLevel:
		match highestLevelReward % 4:
			#A booster pack to start so you have options
			0:
				Persist.game.itemHandler.received_item("Booster Pack")
			#2 Default Cards to build up defences
			1:
				Persist.game.itemHandler.received_item("Default Card", false)
				Persist.game.itemHandler.received_item("Default Card")
			#A perk to start with more power to get to later parts
			2:
				Persist.game.itemHandler.gain_perks(1)
			#A life to face-tank a difficult situation
			3:
				Persist.game.itemHandler.gain_life(1)
		highestLevelReward += 1

##Leave the house
func exit_house() -> void:
	##Reset the sleep timer once you leave the house
	if (not sleepTimer.is_stopped()) and sleepButton.disabled:
		sleepTimer.start()
	##Leave the house proper
	var gameRoot : GameRoot = get_parent()
	gameRoot.switch_scenes()

##Makes you go to sleep
func sleep() -> void:
	var gameRoot : GameRoot = get_parent()
	gameRoot.sleep()
	##Prevent resleeping to ensure that you don't cycle
	sleepButton.disabled = true

func boss_release_slot_updated(slot: CardSlot) -> void:
	#No card means the button shouldn't be enabled
	var slotCard := slot.get_card()
	if slotCard == null:
		bossReleaseButton.disabled = true
		return
	#Gather APID's on this card
	var apIds : PackedInt32Array = []
	for eachCard in slotCard.all_card_data():
		apIds.append(eachCard.apId)
	#Check if any colors aren't part of the bosses
	for eachBandColor in CardUI.ap_ids_to_band_colors(apIds):
		if not (eachBandColor + 1) in Persist.game.defeatedBosses:
			bossReleaseButton.disabled = true
			return
	#If all of them are, you can release for free
	bossReleaseButton.disabled = false

##When you press the boss release button
func boss_release_pressed() -> void:
	var card := bossReleaseSlot.get_card()
	if card != null:
		for eachCard in card.all_card_data():
			eachCard.release()
		bossReleaseSlot.release_card()
	bossReleaseButton.disabled = true
