extends Node
class_name PD

var rng : RandomNumberGenerator
var game : GameData

func _ready() -> void:
	var nSeed : int = randi()
	print(nSeed)
	Persist.set_rand_seed(nSeed)
	
	

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
