extends Resource
class_name ItemHandler

##What type of item each one that gets sent is
enum ItemClasses {NONE, INSTANT, EVENT, INVENTORY}

##An item group that has the AP ID group count
class ApItemGroup:
	var instants : Dictionary[String, int]
	var events : PackedStringArray
	var items : PackedStringArray
	
	##Calls when you get an item to see if the inventory needs to be updated
	func recieved_ap_item(incomingItem : NetworkItem):
		var itemName : String = incomingItem.get_name()
		@warning_ignore("integer_division")
		##The index that is used to determine which color the item is
		var colorIndex : int = ((incomingItem.id - 6500000) / 10000) - 1
		##The index that is used to determine which type of item this actually is
		var itemIndex : int = incomingItem.id % 10000
		var itemClass : ItemClasses
			
		match itemIndex:
			#Default Card
			0:
				itemClass = ItemClasses.INSTANT
			#Money
			1:
				itemClass = ItemClasses.INSTANT
			#Booster Pack
			2:
				itemClass = ItemClasses.EVENT
			#Perk
			3:
				itemClass = ItemClasses.INSTANT
			#Stamp
			1000:
				itemClass = ItemClasses.INVENTORY
			#House Upgrade
			1001:
				itemClass = ItemClasses.INVENTORY
			#Obstacle Busters
			2000:
				itemClass = ItemClasses.INVENTORY
			#Spheres
			3000:
				itemClass = ItemClasses.INVENTORY
			#Traps
			4000:
				match colorIndex:
					0:
						itemClass = ItemClasses.INSTANT
					1:
						itemClass = ItemClasses.EVENT
					2:
						itemClass = ItemClasses.INSTANT
					3:
						itemClass = ItemClasses.INSTANT
					4:
						itemClass = ItemClasses.EVENT
					5:
						itemClass = ItemClasses.EVENT
		
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
##AP items you've used
var usedItems : ApItemGroup
##Default Card Count
var defaultCards : int
##Current Money
var currentMoney : int
##Current Perks
var currentPerks : int

##Emits when the inventory is updated
signal inventory_updated(currentInventory : ApItemGroup)
signal hints_updated()

func _init() -> void:
	Archipelago.conn.obtained_item.connect(recieved_ap_item)
	receivedItems = ApItemGroup.new()
	for eachItem in Archipelago.conn.received_items:
		receivedItems.recieved_ap_item(eachItem)
	if usedItems == null:
		usedItems = ApItemGroup.new()
	update_inventory()

##Calls when you get an item during gameplay
func recieved_ap_item(incomingItem : NetworkItem, updateInventory := true):
	receivedItems.recieved_ap_item(incomingItem)
	if updateInventory:
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
					defaultCards += count
					Persist.gain_card(CardData.new_default())
				"Money":
					currentMoney += count * 10
				"Perk":
					currentPerks += count
				"Unstable Trap":
					for repeat_trap in count:
						unstable_trap()
				"Release Trap":
					for repeat_trap in count:
						release_trap()
				"Trade Down Trap":
					for repeat_trap in count:
						trade_down_trap()
	usedItems.instants = receivedItems.instants.duplicate()
	inventory_updated.emit(currentItems)

##Saves the used items to the json. Received items are saved APSide.
func json_save() -> Dictionary:
	if usedItems == null:
		usedItems = ApItemGroup.new()
	return usedItems.json_save()

##Loads the used items from the json.
func json_load(inData : Dictionary):
	usedItems = ApItemGroup.new()
	usedItems.json_load(inData)

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
	var bestCards := PD.get_best(Persist.currentCards, func(a) : return a.card_quality())
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
	toGain.scout()
	Persist.gain_card(toGain)

##Creates the current inventory
func current_inventory() -> ApItemGroup:
	return receivedItems.get_difference(usedItems)

##When you scout a card this function will run
func new_known_card(itemData : NetworkItem):
	itemData.output()
	hints_updated.emit()
