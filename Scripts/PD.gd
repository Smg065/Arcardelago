extends Node
class_name PD

##The RNG based on AP's seed
var rng : RandomNumberGenerator
##The game's difficulty
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
##The order the sphere worlds are in
var worldOrder : Dictionary
##The seed of this game
var apSeed : int
##The AP's game data
var game : GameData

##What cards you have right now
var currentCards : Array[CardData]

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

##Runs the callable over each entry in an iterable, and returns the value(s) that are the highest. Invert for lowest.
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
	#Don't use the RNG if there's no options, for seed stability
	if inArray.size() == 1:
		return inArray[0]
	#Use the RNG if there's 2 or more options
	return inArray[rng.randi_range(0, inArray.size() - 1)]

##Takes the server data about this game and stores them
func hold_server_data(slotData : Dictionary) -> void:
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
	##Get your spawning sphere
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
