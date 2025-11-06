extends Control
class_name InventoryUI

const HalfModulated = Color(.5,.5,.5 ,.5)

##Displays the spheres you have.
@export var sphereIcons : Array[TextureRect]
##Displays the money you have.
@export var goldLabel : Label
##Displays the hint points.
@export var hintPointLabel : Label
##Displays the lives you have.
@export var lifeLabel : Label
##Displays the burgers you have.
@export var burgel : Label
##Displays the house level.
@export var houseUpgradeLabel : Label
##Displays the backdrops of reachable regions.
@export var backdropStrips : Array[ColorRect]

@export_category("Base")
##The region bars that show what you've found.
@export var foundBars : Array[ProgressBar]
##The region bars that show what you've released.
@export var releasedBars : Array[ProgressBar]
##The text that displays your progress in each region.
@export var foundReleasedText : Array[Label]

@export_category("Obstacle Breakers")
##The icons that display what region item busters you have
@export var obsticalBreakerIcons : Array[TextureRect]

@export_category("Stamps")
##The icons that display what region item busters you have
@export var stampIcons : Array[TextureRect]
##The icons that display what region item busters you have
@export var stampCounts : Array[Label]

@export_category("Events")
@export var eventQueueHolder : HBoxContainer
@export var queueTabPrefab : PackedScene
@export var eventTextureTable : Dictionary[String, Texture2D]
##The release conditions for the events
@export var eventReleaseTable : Dictionary[String, QueuedEvent.ReleaseType]

func _ready() -> void:
	for eachBar in foundBars:
		eachBar.max_value = Persist.cardsPerRegion
	for eachBar in releasedBars:
		eachBar.max_value = Persist.cardsPerRegion
	Persist.game.itemHandler.inventory_updated.connect(update_visuals)
	Persist.game.itemHandler.hints_updated.connect(update_bars)
	Persist.game.itemHandler.cash_updated.connect(update_counters)
	Persist.game.itemHandler.burgdated.connect(update_counters)
	Persist.game.itemHandler.lives_updated.connect(update_counters)
	Persist.game.itemHandler.update_inventory()
	#Archipelago.conn.

##Updates the items you've collected as visuals
func update_visuals(currentInventory : ItemHandler.ApItemGroup):
	var permanentItems : PackedStringArray = Persist.game.itemHandler.receivedItems.items
	houseUpgradeLabel.text = "House Lvl: %s" % (currentInventory.items.count("House Upgrade") + 1)
	#Items
	for eachColor in 6:
		var colorName = ColorCatagory.COLOR_NAMES[eachColor]
		#If you have that color sphere
		sphereIcons[eachColor].visible = permanentItems.has(colorName + " Sphere")
		#If you've reached the region of this color
		if Persist.game.reached_regions().has(colorName):
			backdropStrips[eachColor].modulate = Color.WHITE
		else:
			backdropStrips[eachColor].modulate = HalfModulated
		#Obstacle Breakers
		if currentInventory.items.has(obsticalBreakerIcons[eachColor].name):
			obsticalBreakerIcons[eachColor].modulate = Color.WHITE
		else:
			obsticalBreakerIcons[eachColor].modulate = HalfModulated
		#Stamps
		var stampCount : int = currentInventory.items.count(stampIcons[eachColor].name)
		if stampCount > 0:
			stampIcons[eachColor].modulate = Color.WHITE
		else:
			stampIcons[eachColor].modulate = HalfModulated
		stampCounts[eachColor].text = "x%s" % stampCount
	#Events
	for eachChild in eventQueueHolder.get_children():
		eachChild.queue_free()
	for eachEvent in currentInventory.events:
		var newQueueTab : QueuedEvent = queueTabPrefab.instantiate()
		eventQueueHolder.add_child(newQueueTab)
		newQueueTab.eventName = eachEvent
		newQueueTab.get_child(0).texture = eventTextureTable[eachEvent]
		newQueueTab.releaseType = eventReleaseTable[eachEvent]
		newQueueTab.tooltip_text = newQueueTab.eventName
	update_bars()

##Update the bars showing item information progress
func update_bars(_inHints : Array[NetworkHint] = []):
	for eachColor in 6:
		#Bars
		var foundCards : int = 0
		var releasedCards : int = 0
		for eachLocation in Archipelago.conn.slot_locations:
			@warning_ignore("integer_division")
			var cardColor : int = (eachLocation - 65000) / 100
			if cardColor == eachColor:
				if Archipelago.conn.slot_locations[eachLocation]:
					releasedCards += 1
					foundCards += 1
				elif Persist.game.knownLoctions.has(eachLocation):
					foundCards += 1
		foundBars[eachColor].value = foundCards
		releasedBars[eachColor].value = releasedCards
		foundReleasedText[eachColor].text = "%2d:%2d" % [Persist.cardsPerRegion - foundCards, Persist.cardsPerRegion - releasedCards]

##Update the gold and hint points
func update_counters() -> void:
	goldLabel.text = ": %04d" % Persist.game.itemHandler.currentMoney
	var hintCost : int = roundi(Archipelago.conn.slot_locations.size() * (Archipelago.conn.hint_cost / 100))
	var locationsChecked : int = 0
	for eachCheck in Archipelago.conn.locations:
		if Archipelago.conn.locations[eachCheck].hint_status == NetworkHint.Status.FOUND:
			locationsChecked += 1
	locationsChecked *= Archipelago.conn.location_check_points
	hintPointLabel.text = ": %03d/%03d" % [locationsChecked, hintCost]
	burgel.text = ": %04d" % Persist.game.itemHandler.curgers
	lifeLabel.text = ": %02d" % Persist.game.itemHandler.currentLives
