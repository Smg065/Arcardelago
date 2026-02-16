extends Node
class_name PD

##The smallest an int can be
const MIN_INT = -9223372036854775808

##A table that converts a region index to the text name
const REGION_TO_NAME = {0 : "White", 1 : "Red", 2 : "Green", 3 : "Violet", 4 : "Orange", 5 : "Blue", 6 : "Yellow"}

##The RNG based on AP's seed
var rng : RandomNumberGenerator
##The game's difficulty[br]
##0 = Easy
##1 = Normal
##2 = Hard
var difficulty : int
##How many cards are in your region
var cardsPerRegion : int
##How wide the map's radius is
var mapRadius : int
##How many tiles there are per map node
var tileDensity : int
##Odds of node types appearing
var nodePercents : Dictionary
##The sphere you spawn with
var spawnSphere : ColorCatagory.ColorTypes
##The player who determines the final boss
var finalBossOrigin : String
##The order the sphere worlds are in
var worldOrder : Dictionary
##The depth of all regions based on the spawn sphere
var dfsRegions : Dictionary
##The number of gates you must open to directly go from spawn to the final boss.
var gameDepth : int
##The name of the region you spawn from
var spawnName : String
##The chance that a trap will auto-release at the end of combat
var trapReleaseChance : int = 10
##If the region should require a blocker or not
var priorityBreakers : Dictionary
##The seed of this game
var apSeed : int
##The AP's game data
var game : GameData
##Hint Points
var hintPoints : int
##If you see the image on the card by default
var imageByDefault : bool = true

##Shop items, where the value is the weight that they show up.
static var shopItemTable : Dictionary[ShopItemInfo, int] = {
	load("res://Resources/ShopItems/BoosterPack.tres") : 4,
	load("res://Resources/ShopItems/Burger.tres") : 10,
	load("res://Resources/ShopItems/ExtraLife.tres") : 1,
	load("res://Resources/ShopItems/Perk.tres") : 6,
	load("res://Resources/ShopItems/RandomCard.tres") : 6,
	load("res://Resources/ShopItems/Scout.tres") : 10,
	load("res://Resources/ShopItems/Shield.tres") : 2,
	load("res://Resources/ShopItems/Treasure.tres") : 2
}

##Treasure items, where the value is the copies of the given item.
static var treasureItemTable : Dictionary[ItemInfo, int] = {
	load("res://Resources/ShopItems/Scout.tres") : 5,
	load("res://Resources/Items/DefaultCard.tres") : 4,
	load("res://Resources/ShopItems/Burger.tres") : 3,
	load("res://Resources/ShopItems/Perk.tres") : 2,
	load("res://Resources/ShopItems/RandomCard.tres") : 2,
	load("res://Resources/ShopItems/BoosterPack.tres") : 1,
	load("res://Resources/ShopItems/ExtraLife.tres") : 1,
	load("res://Resources/ShopItems/Shield.tres") : 1,
	load("res://Resources/Items/Money.tres") : 1,
	load("res://Resources/Items/Release.tres") : 1
}

##What cards you have right now
var currentCards : Array[CardData]
##Emit when your current cards change
signal deck_changed()

##Makes a dictionary either create a new array at a key or append to it
static func append_dict_entry(dict : Dictionary, key, value) -> Dictionary:
	if dict.has(key):
		dict[key].append(value)
	else:
		dict[key] = [value]
	return dict

##Searches a graph dictionary depth-first, returning Dictionary[Node, Depth]
static func depth_first_search(graph : Dictionary, node, depth : int = 0) -> Dictionary:
	var output := {node:depth}
	for eachChild in graph[node]:
		var result := depth_first_search(graph, eachChild, depth + 1)
		for eachResult in result:
			output[eachResult] = result[eachResult]
	return output

##Get the path you need to take to get to the entry
static func get_graph_path(graph : Dictionary, node, goal) -> Array:
	var output := []
	if node == goal:
		return [node]
	for eachChild in graph[node]:
		var result := get_graph_path(graph, eachChild, goal)
		if result.has(goal):
			output.append(node)
			output.append_array(result)
	return output

##Returns Iterable[Key]
static func square_bracket(key, iterable):
	return iterable[key]

##Runs the callable over each entry in an iterable, and returns the value(s) that are the highest. Invert for lowest.[br]
##Callale 
static func get_best(iteratable, callable : Callable, isLesser := false) -> Array:
	var output = []
	var bestVal = -99999999
	if isLesser:
		bestVal = -bestVal
	for eachEntry in iteratable:
		var result = callable.call(eachEntry)
		if is_equal_approx(bestVal, result):
			output.append(eachEntry)
		elif (result > bestVal) != isLesser:
			bestVal = result
			output = [eachEntry]
	return output

##Set the random seed to this
func set_rand_seed(newSeed : int):
	rng = RandomNumberGenerator.new()
	rng.seed = newSeed

##Get a random color from the ranges
func random_color(hMn : float, hMx : float, sMn : float, sMx : float, vMn : float, vMx : float):
	var randH := rng.randf_range(hMn, hMx)
	var randS := rng.randf_range(sMn, sMx)
	var randV := rng.randf_range(vMn, vMx)
	return Color.from_hsv(randH, randS, randV)

##Picks a random element from the random seed
func pick_random(inArray : Array):
	#Just use the seeded version but pass in this seed
	return seeded_pick_random(rng, inArray)

##A static version of pick random that takes RNG as an input
static func seeded_pick_random(inRng : RandomNumberGenerator, inArray : Array):
	#Don't use the RNG if there's no options, for seed stability
	if inArray.size() == 1:
		return inArray[0]
	#Use the RNG if there's 2 or more options
	return inArray[inRng.randi_range(0, inArray.size() - 1)]

##Takes the slot data about this game and stores them
func hold_server_data(inData : Dictionary) -> void:
	var slotData : Dictionary = inData["slot_data"]
	difficulty = slotData["difficulty"]
	cardsPerRegion = slotData["cards_per_region"]
	mapRadius = slotData["map_radius"]
	tileDensity = slotData["tiles_per_pip"]
	nodePercents = slotData["node_percentages"]
	#Nodes with 0% Chance will not randomly be selected
	var toDelete : Array[String]
	for eachEntry in nodePercents.keys():
		if is_zero_approx(nodePercents[eachEntry]):
			toDelete = eachEntry
	for eachEntry in toDelete:
		nodePercents.erase(eachEntry)
	match slotData["spawning_sphere"]:
		"Red Sphere":
			spawnSphere = ColorCatagory.RED
		"Green Sphere":
			spawnSphere = ColorCatagory.GREEN
		"Violet Sphere":
			spawnSphere = ColorCatagory.VIOLET
		"Orange Sphere":
			spawnSphere = ColorCatagory.ORANGE
		"Blue Sphere":
			spawnSphere = ColorCatagory.BLUE
		"Yellow Sphere":
			spawnSphere = ColorCatagory.YELLOW
	worldOrder = slotData["world_order"]
	#The player who determines the final boss
	finalBossOrigin = slotData["final_boss_origin"]
	#The odds that a trap will self-release
	trapReleaseChance = slotData["trap_release_chance"]
	#The odds that a trap will self-release
	priorityBreakers = slotData["breaker_priority"]
	#Where you spawn from
	spawnName = slotData["spawning_sphere"].split(' ')[0]
	#Get the world order as a depth-first sorted dictionary
	dfsRegions = depth_first_search(worldOrder, spawnName)
	#Any of the deepest regions would show the game depth
	gameDepth = dfsRegions[get_best(dfsRegions, square_bracket.bind(dfsRegions))[0]]
	#Add 1 for the final boss region
	gameDepth += 1
	apSeed = slotData["seed"]
	set_rand_seed(apSeed)

##Get the percentage that all the listed pip types take up in the generation
func pip_percentage(types : PackedStringArray):
	var outSum : float = 0
	for eachType in types:
		outSum += nodePercents[eachType]
	#No divide by 0s
	if is_zero_approx(outSum):
		return 0
	return outSum / 100.0

##Gets the difficulty score of the furthest depth
func end_game_difficulty() -> int:
	match difficulty:
		#Easy
		0:
			return 100
		#Hard
		2:
			return 200
		#Normal
		_:
			return 150

##Highest quality cards in the given card list
static func best_cards(inCards : Array[CardData]) -> Array[CardData]:
	var outCards : Array[CardData]
	outCards.append_array(PD.get_best(inCards, func(a) : return a.card_quality()) as Array[CardData])
	return outCards

##Current Deck without cards that can't be released
func releasable_cards() -> Array[CardData]:
	var output : Array[CardData]
	for eachCard in currentCards:
		if eachCard.isDefault or eachCard.enemyCard:
			continue
		output.append(eachCard)
	return output

##Remove a card from your current cards
func lose_card(toLose : CardData):
	currentCards.erase(toLose)
	deck_changed.emit()

##Put a card in your current cards
func gain_card(toGain : CardData):
	currentCards.append(toGain)
	deck_changed.emit()

##Lose all non-location, non-default cards
func clear_cards():
	var expendableCards : Array[CardData]
	for eachCard in currentCards:
		if eachCard.isDefault:
			continue
		if eachCard.enemyCard:
			continue
		expendableCards.append(eachCard)
	for eachCard in expendableCards:
		currentCards.erase(eachCard)
	deck_changed.emit()

##Put a random card in your current cards
func gain_random():
	var currentCardpool := game.current_cardpool()
	if currentCardpool.size() > 0:
		gain_card(currentCardpool.pick_random())
	else:
		gain_card(CardData.new_default())
