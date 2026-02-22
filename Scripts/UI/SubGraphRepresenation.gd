extends GraphNode
class_name SubGraphRepresenation

##The graph this node represents
@export var graph : CardEditorSubGraph
##All the input options
@export var inputs : Array[GraphTypeSelector]
##All the output options
@export var outputs : Array[GraphTypeSelector]
var graphTypePrefab = load("res://Resources/SetEditor/GraphTypeSelector.tscn")

const TOP_TEXT_SIZE = 3
const COLOR_BY_TYPE = [Color("767ebd"),Color("75c274"),Color("ffffff"),
Color("00000000"),Color("c97582"),Color("eee391"),Color("c994c2"),Color("d8a07d")]

##Create a type selector of the given type
func create_type_selector(isInput : bool) -> GraphTypeSelector:
	var newTypeSelector : GraphTypeSelector = graphTypePrefab.instantiate()
	var subTypeSelector : GraphTypeSelector = graphTypePrefab.instantiate()
	newTypeSelector.pair(subTypeSelector)
	add_child(newTypeSelector)
	var newIndex : int = -2
	if isInput:
		newIndex = TOP_TEXT_SIZE + inputs.size()
		inputs.append(newTypeSelector)
	else:
		outputs.append(newTypeSelector)
	subTypeSelector.attach_relay(graph, isInput)
	move_child(newTypeSelector, newIndex)
	newTypeSelector.attach_subgraph_rep(self, isInput)
	subTypeSelector.attach_subgraph_rep(self, isInput, newTypeSelector)
	update_shift_buttons()
	return newTypeSelector

##Removes a type selector of the given type
func remove_type_selector(toDeleteTypeSelector : GraphTypeSelector, isInput : bool):
	if isInput:
		var eraseIndex : int = inputs.find(toDeleteTypeSelector)
		inputs.erase(toDeleteTypeSelector)
		graph.graphIn.get_child(eraseIndex).queue_free()
	else:
		var eraseIndex : int = outputs.find(toDeleteTypeSelector)
		outputs.erase(toDeleteTypeSelector)
		graph.graphOut.get_child(eraseIndex).queue_free()
	toDeleteTypeSelector.queue_free()
	call_deferred("update_shift_buttons")

##Updates the typings on items when a new option is selected
func type_changed(_newType : int):
	update_shift_buttons()

##Subgraphs
func update_shift_buttons():
	clear_slot(0)
	clear_slot(1)
	clear_slot(2)
	var inputSize : int = inputs.size()
	for inputIndex in inputSize:
		var eachInput : GraphTypeSelector = inputs[inputIndex]
		eachInput.update_shift_buttons(inputIndex, inputSize)
		graph.graphIn.get_child(inputIndex).update_shift_buttons(inputIndex, inputSize)
		var type = eachInput.optionButton.get_selected_id()
		update_slot_type(self, TOP_TEXT_SIZE + inputIndex, type, true)
		update_slot_type(graph.graphIn, inputIndex, type, false)
	graph.graphIn.clear_slot(inputSize)
	clear_slot(inputSize + 3)
	clear_slot(inputSize + 4)
	clear_slot(inputSize + 5)
	var outputOffset : int = TOP_TEXT_SIZE + inputSize + 3
	var outputSize = outputs.size()
	for outputIndex in outputSize:
		var eachOutput : GraphTypeSelector = outputs[outputIndex]
		eachOutput.update_shift_buttons(outputIndex, outputSize)
		graph.graphOut.get_child(outputIndex).update_shift_buttons(outputIndex, outputSize)
		var type = eachOutput.optionButton.get_selected_id()
		update_slot_type(self, outputOffset + outputIndex, type, false)
		update_slot_type(graph.graphOut, outputIndex, type, true)
	graph.graphOut.clear_slot(outputSize)
	clear_slot(outputOffset + outputSize)

##Sets the slot type in a given position
func update_slot_type(targetGraph : GraphNode, index : int, type : int, isInput : bool):
	targetGraph.set_slot(index, isInput, type, COLOR_BY_TYPE[type], !isInput, type, COLOR_BY_TYPE[type])

func set_subgroup_name(newText: String) -> void:
	graph.emit_signal("name_changed", graph, newText)
