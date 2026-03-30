extends GraphNode
class_name GNArray

@export var optionButton : OptionButton
@export var array : Array

func _ready() -> void:
	relay_type_options(get_parent())

##Append the relays to the option buttons
func relay_type_options(graph : GraphEdit):
	for eachEntry in graph.type_names:
		optionButton.add_item(graph.type_names[eachEntry], eachEntry)
