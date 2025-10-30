extends Control
class_name InventoryUI

const HalfModulated = Color(1,1,1,.5)

##Displays the spheres you have.
@export var sphereIcons : Array[TextureRect]
##Displays the money you have.
@export var goldLabel : Label
##Displays the hint points.
@export var hintPointLabel : Label
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

func _ready() -> void:
	for eachBar in foundBars:
		eachBar.max_value = Persist.cardsPerRegion
	for eachBar in releasedBars:
		eachBar.max_value = Persist.cardsPerRegion
	Persist.game.itemHandler.inventory_updated.connect(update_visuals)
	Persist.game.itemHandler.update_inventory()
	Archipelago.conn.set_hint_notify(update_bars)
	#Archipelago.conn.

func update_visuals(currentInventory : ItemHandler.ApItemGroup):
	var permanentItems : PackedStringArray = Persist.game.itemHandler.receivedItems.items
	var usedItems : PackedStringArray = Persist.game.itemHandler.usedItems.items
	for eachColor in 6:
		var colorName = ColorCatagory.COLOR_NAMES[eachColor]
		#If you have that color sphere
		sphereIcons[eachColor].visible = permanentItems.has(colorName + " Sphere")
		#If you've reached the region of this color
		if sphereIcons[eachColor].visible and usedItems.has(colorName + " Sphere"):
			backdropStrips[eachColor].modulate = HalfModulated
		else:
			backdropStrips[eachColor].modulate = Color.WHITE
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
	update_bars([])

func update_bars(_inHints : Array[NetworkHint]):
	var hintedLocations : PackedInt64Array
	for eachHint in Archipelago.conn.hints:
		if eachHint.is_local():
			hintedLocations.append(eachHint.item.loc_id)
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
				if hintedLocations.has(eachLocation):
					foundCards += 1
		foundBars[eachColor].value = foundCards
		releasedBars[eachColor].value = releasedCards
		foundReleasedText[eachColor].text = "%2d:%2d" % [Persist.cardsPerRegion - foundCards, Persist.cardsPerRegion - releasedCards]
	
