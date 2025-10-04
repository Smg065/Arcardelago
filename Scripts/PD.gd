extends Node
class_name PD

var rng : RandomNumberGenerator
var game : GameData

##Makes a dictionary either create a new array at a key or append to it
static func append_dict_entry(dict : Dictionary, key, value) -> Dictionary:
	if dict.has(key):
		dict[key].append(value)
	else:
		dict[key] = [value]
	return dict

##Picks a random element from the random seed
func pick_random(inArray : Array):
	if rng == null:
		rng = RandomNumberGenerator.new()
	return inArray[rng.randi_range(0, inArray.size() - 1)]
