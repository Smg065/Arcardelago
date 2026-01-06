extends Resource
class_name ItemHandler

##What type of item each one that gets sent is
enum ItemClasses {NONE, INSTANT, EVENT, INVENTORY}

##Instant Item Class
const INSTANT = ItemClasses.INSTANT
##Event Item Class
const EVENT = ItemClasses.EVENT
##Inventory Item Class
const INVENTORY = ItemClasses.INVENTORY

##The table containing all item names to item types.
const ITEM_NAME_TABLE : Dictionary[String, ItemClasses] = {
	#Filler
	"Default Card"    : INSTANT,
	"Money"           : INSTANT,
	"Booster Pack"    : EVENT,
	"Perk"            : INSTANT,
	"Random Card"     : INSTANT,
	"Scout"           : INSTANT,
	"Shield"          : EVENT,
	"Treasure"        : EVENT,
	"Burger"          : INSTANT,
	"Extra Life"      : INSTANT,
	#Useful
	"Steel Stamp"     : INVENTORY,
	"Harmony Stamp"   : INVENTORY,
	"Ghost Stamp"     : INVENTORY,
	"Square Stamp"    : INVENTORY,
	"Gold Stamp"      : INVENTORY,
	"House Upgrade"   : INVENTORY,
	#Progression
	"Bottle"          : INVENTORY,
	"Axe"             : INVENTORY,
	"Castle Key"      : INVENTORY,
	"Pickaxe"         : INVENTORY,
	"Boat"            : INVENTORY,
	"Shovel"          : INVENTORY,
	#Proguseful
	"Red Sphere"      : INVENTORY,
	"Green Sphere"    : INVENTORY,
	"Violet Sphere"   : INVENTORY,
	"Orange Sphere"   : INVENTORY,
	"Blue Sphere"     : INVENTORY,
	"Yellow Sphere"   : INVENTORY,
	#Traps
	"Unstable Trap"   : INSTANT,
	"Fog Trap"        : EVENT,
	"Release Trap"    : INSTANT,
	"Trade Down Trap" : INSTANT,
	"Stackless Trap"  : EVENT,
	"Blind Trap"      : EVENT
}

##An item group that holds AP-Compatable items.
class ApItemGroup:
	var instants : Dictionary[String, int]
	var events : PackedStringArray
	var items : PackedStringArray
	
	##Calls when you get an item to see if the inventory needs to be updated
	func received_ap_item(incomingItem : NetworkItem):
		var itemName : String = incomingItem.get_name()
		received_item(itemName)
	
	##Non-ap version of item reception
	func received_item(itemName : String):
		var itemClass : ItemClasses = ItemClasses.NONE
		if ITEM_NAME_TABLE.has(itemName):
			itemClass = ITEM_NAME_TABLE[itemName]
		match itemClass:
			ItemClasses.INSTANT:
				if instants.has(itemName):
					instants[itemName] += 1
				else:
					instants[itemName] = 1
			ItemClasses.EVENT:
				events.append(itemName)
			ItemClasses.INVENTORY:
				items.append(itemName)
			_:
				push_error("No item class found for item " + itemName)
	
	##Used to combine local and received APItems
	func combine(combineGroup : ApItemGroup) -> ApItemGroup:
		var output := ApItemGroup.new()
		output.instants.merge(instants)
		for otherInstants in combineGroup.instants:
			if output.instants.has(otherInstants):
				output.instants[otherInstants] += combineGroup.instants[otherInstants]
			else:
				output.instants[otherInstants] = combineGroup.instants[otherInstants]
		output.events.append_array(events)
		output.events.append_array(combineGroup.events)
		output.items.append_array(items)
		output.items.append_array(combineGroup.items)
		return output
	
	##Called on received items, using used items as an input, to create the current items
	func get_difference(comparedGroup : ApItemGroup) -> ApItemGroup:
		##The items you have access to
		var currentItems : ApItemGroup = ApItemGroup.new()
		for eachEntry in instants:
			currentItems.instants[eachEntry] = instants[eachEntry]
			if comparedGroup.instants.has(eachEntry):
				currentItems.instants[eachEntry] -= comparedGroup.instants[eachEntry]
		#Skip this if you've used all events so far
		currentItems.events = events.duplicate()
		for eachEntry in comparedGroup.events:
			currentItems.events.erase(eachEntry)
		#Skip this if you've used all events so far
		currentItems.items = items.duplicate()
		for eachEntry in comparedGroup.items:
			currentItems.items.erase(eachEntry)
		return currentItems
	
	##Save Json
	func json_save():
		return {
			"instants" : instants,
			"events" : events,
			"items" : items
		}
	
	##Load Json
	func json_load(inData : Dictionary):
		if inData == {}:
			return
		instants.clear()
		for eachKey in inData["instants"]:
			instants[eachKey] = int(inData["instants"][eachKey])
		events = inData["events"]
		items = inData["items"]

##AP items you received
var receivedItems : ApItemGroup
##Items that are sendable by AP but you found locally.
var localItems : ApItemGroup
##Items you've used
var usedItems : ApItemGroup
##Current Money
var currentMoney : int
##Current Perks
var currentPerks : int
##Current Burgers
var curgers : int
##The total burgers you have found
var burgotals : int
##Current Exra Lives
var currentLives : int
##Overscouts
var overscouts : int

##Emits when the inventory is updated
signal inventory_updated(currentInventory : ApItemGroup)
##Emits when new locations are cleared
signal hints_updated()
##Emits when your money changes
signal cash_updated()
##Emits when you gain a perk
signal perks_updated()
##Emits when your burgers change
signal burgdated()
##Emits when your lives are updated
signal lives_updated()
##Emits when you scout past the scouting total
signal overscouts_updated()

func _init() -> void:
	Archipelago.conn.obtained_item.connect(received_ap_item)
	receivedItems = ApItemGroup.new()
	localItems = ApItemGroup.new()
	for eachItem in Archipelago.conn.received_items:
		receivedItems.recieved_ap_item(eachItem)
	if usedItems == null:
		usedItems = ApItemGroup.new()
	update_inventory()

##Spend money and update display for it
func spend(cost : int, target):
	currentMoney -= cost
	cash_updated.emit()
	#Bought card data
	if target is CardUI:
		CSM.addoccur("Spent Gold", {"Spent" : cost, "CardData" : target.all_card_data()})
	#Bought shop info
	if target is ShopItemInfo:
		CSM.addoccur("Spent Gold", {"Spent" : cost, "ShopItem" : target})
	CSM.setcount("Inventory Gold", currentMoney)

##Earn money and update the display for it
func earn(income : int, source : String):
	currentMoney += income
	cash_updated.emit()
	CSM.addoccur("Earned Gold", source)
	CSM.setcount("Inventory Gold", currentMoney)

##Increases the total perks you have
func gain_perks(newPerks : int):
	currentPerks += newPerks
	perks_updated.emit()

##Increases the total burgers you have
func burgain(burgearnings : int):
	curgers += burgearnings
	burgotals += burgearnings
	burgdated.emit()
	CSM.setcount("Inventory Burgers", curgers)

##Decrease the total burgers you have
func eat(orderSize : int):
	curgers -= orderSize
	burgdated.emit()
	CSM.setcount("Inventory Burgers", curgers)

##Increases the total extra lives you have
func gain_life(newLives : int):
	currentLives += newLives
	lives_updated.emit()
	CSM.setcount("Inventory Lives", currentLives)

##Dedcrease the total extra lives you have.[br]
##Returns false if there's no lives remaining
func lose_life() -> bool:
	if currentLives == 0:
		return false
	currentLives -= 1
	lives_updated.emit()
	CSM.setcount("Inventory Lives", currentLives)
	return true

##Increase the number of scouts you've done that exceed the scout cap
func increase_overscouts():
	overscouts += 1
	overscouts_updated.emit()

##Calls when you get an item during gameplay
func received_ap_item(incomingItem : NetworkItem, updateInventory := true):
	receivedItems.received_ap_item(incomingItem)
	if updateInventory:
		update_inventory()

##Calls when you find an item in your own world
func received_item(incomingItem : String, updateOnComplete : bool = true):
	localItems.received_item(incomingItem)
	if updateOnComplete:
		update_inventory()

##Call to update the inventory for gameplay
func update_inventory():
	if receivedItems == null:
		receivedItems = ApItemGroup.new()
	var currentItems := current_inventory()
	for eachType in currentItems.instants:
		if currentItems.instants[eachType] > 0:
			var count = currentItems.instants[eachType]
			match eachType:
				"Default Card":
					for eachDefault in count:
						Persist.gain_card(CardData.new_default())
				"Money":
					earn(count * 10, "Item")
				"Perk":
					gain_perks(count)
				"Random Card":
					for eachScout in count:
						Persist.gain_random()
				"Scout":
					for eachScout in count:
						Persist.game.scout_unknown()
				"Burger":
					burgain(count)
				"Extra Life":
					gain_life(count)
				"Unstable Trap":
					for repeat_trap in count:
						unstable_trap()
				"Release Trap":
					for repeat_trap in count:
						release_trap()
				"Trade Down Trap":
					for repeat_trap in count:
						trade_down_trap()
	usedItems.instants = localItems.combine(receivedItems).instants
	inventory_updated.emit(currentItems)

##Saves the used items to the json. Received items are saved APSide.
func json_save() -> Dictionary:
	if usedItems == null:
		usedItems = ApItemGroup.new()
	if localItems == null:
		localItems = ApItemGroup.new()
	return {
		"usedItems" : usedItems.json_save(),
		"localItems" : localItems.json_save(),
		"currentMoney" : currentMoney,
		"currentPerks" : currentPerks,
		"curgers" : curgers,
		"burgotals" : burgotals,
		"currentLives" : currentLives,
		"overscouts" : overscouts
		}

##Loads the used items from the json.
func json_load(inData : Dictionary):
	usedItems = ApItemGroup.new()
	localItems = ApItemGroup.new()
	usedItems.json_load(inData["usedItems"])
	localItems.json_load(inData["localItems"])
	currentMoney = inData["currentMoney"]
	currentPerks = inData["currentPerks"]
	curgers = inData["curgers"]
	burgotals = inData["burgotals"]
	currentLives = inData["currentLives"]
	overscouts = inData["overscouts"]

##Each trap card you own has a 50% chance to release
func unstable_trap():
	var toRelease : Array[CardData]
	for eachCard in Persist.currentCards:
		#For each trap card
		if eachCard.apItemFlags >= 4 and !eachCard.enemyCard and !eachCard.isDefault:
			if Persist.rng.randi_range(0, 1) == 0:
				toRelease.append(eachCard)
	for eachReleased in toRelease:
		eachReleased.release()

##Releases a random card you own
func release_trap():
	var releasableCards := Persist.releasable_cards()
	if releasableCards.size() > 0:
		releasableCards.pick_random().release()

##Replaces one of the highest value cards you own with one of a lower quality
func trade_down_trap():
	var bestCards := PD.best_cards(Persist.currentCards)
	#No cards in your deck means stop here
	if bestCards.size() == 0:
		return
	##The high quality card you're replacing
	var toLose : CardData = bestCards.pick_random()
	#Cardpool
	var highestScore : int = toLose.card_quality()
	#You can lose default cards this way. Can't lose harmonized cards.
	if highestScore == 0:
		return
	##Cards that are of lower quality than the highest quality items
	var worseCards : Array[CardData]
	for eachCard in Persist.game.current_cardpool():
		var eachQuality = eachCard.card_quality()
		if eachQuality < highestScore:
			worseCards.append(eachCard)
	worseCards.append(CardData.new_default())
	##The card that the target card will become
	var toGain : CardData = worseCards.pick_random()
	Persist.lose_card(toLose)
	if !toGain.isDefault:
		toGain.scout()
	Persist.gain_card(toGain)

##Creates the current inventory
func current_inventory() -> ApItemGroup:
	var currentInventory := localItems.combine(receivedItems).get_difference(usedItems)
	CSM.setoccur("Inventory Items", currentInventory.items)
	CSM.setoccur("Inventory Events", currentInventory.events)
	return currentInventory

##When you scout a card this function will run
func new_known_card(itemData : NetworkItem):
	itemData.output()
	hints_updated.emit()

##Try to activate an event
func try_event(eventName : String) -> bool:
	if current_inventory().events.has(eventName):
		usedItems.events.append(eventName)
		return true
	return false

##Use the item
func use_item(itemName : String, reusable : bool = false) -> bool:
	if reusable:
		if receivedItems.items.has(itemName):
			if !usedItems.items.has(itemName):
				usedItems.items.append(itemName)
			return true
		return false
	if current_inventory().items.has(itemName):
		usedItems.items.append(itemName)
		return true
	return false
