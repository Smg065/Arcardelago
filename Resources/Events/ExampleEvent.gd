extends EventNodeData

func _init() -> void:
	eventColors = 0b111111
	eventName = "DEFAULT"
	eventWeight = 10
	eventMinDifficulty = 0
	eventMaxDifficulty = 2
	eventImage = load("res://icon.svg")
	eventText = "[center]If you see this event, this is a placeholder!"
	eventOptions = {"Example" : example_function, "Exit" : exit}

##Default exit option
func example_function(_eventScreen : EventScreen):
	print("Hello World!")
