extends Resource
class_name WordWeight

@export var word : String = ""
@export_range(-1, 1) var weight : float = 0 

func save_json() -> Dictionary:
	return {
		"word" : word,
		"weight" : weight
	}

func load_json(saveData : Dictionary):
	word = saveData["word"]
	weight = saveData["weight"]
