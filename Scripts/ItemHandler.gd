extends Resource
class_name Inventory

enum ItemClasses {NONE, INSTANT, EVENT, INVENTORY}

class ApItemGroup:
	var instants : Dictionary[String, int]
	var events : PackedStringArray
	var items : PackedStringArray
	
	##Calls when you get an item to see if the inventory needs to be updated
	func recieved_ap_item(incomingItem : NetworkItem):
		var itemName : String = incomingItem.get_name()
		print(itemName)
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
			if comparedGroup.instants.has(eachEntry):
				currentItems[eachEntry] = instants[eachEntry] - comparedGroup[eachEntry]
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
	func load_json(inData : Dictionary):
		instants = inData["instants"]
		events = inData["events"]
		items = inData["items"]

var receivedItems : ApItemGroup
var usedItems : ApItemGroup

##Emits when the inventory is updated
signal inventory_updated(currentInventory : ApItemGroup)

func _ready():
	Archipelago.conn.obtained_item.connect(recieved_ap_item)
	receivedItems = ApItemGroup.new()
	for eachItem in Archipelago.conn.received_items:
		receivedItems.recieved_ap_item(eachItem)
	usedItems = ApItemGroup.new()

##Calls when you get an item during gameplay
func recieved_ap_item(incomingItem : NetworkItem):
	receivedItems.recieved_ap_item(incomingItem)
	update_inventory()

##Call to update the inventory for gameplay
func update_inventory():
	inventory_updated.emit(receivedItems.get_difference(usedItems))

##Saves the used items to the json. Received items are saved APSide.
func json_save() -> Dictionary:
	return usedItems.json_save()

##Loads the used items from the json.
func json_load(inData : Dictionary):
	usedItems.json_load(inData)
	update_inventory()
