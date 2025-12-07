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
			Persist.game.itemHandler.earn(toEarn)
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
	var gameRoot : GameRoot = get_parent()
	gameRoot.switch_scenes()
