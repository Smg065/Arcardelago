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

##Makes a dictionary either create a new array at a key or append to it
static func append_dict_entry(dict : Dictionary, key, value) -> Dictionary:
	if dict.has(key):
		dict[key].append(value)
	else:
		dict[key] = [value]
	return dict

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
	nodePercents = slotData["node_percentages"]
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
