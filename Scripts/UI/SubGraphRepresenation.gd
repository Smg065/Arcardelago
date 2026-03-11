extends CEGNBase
class_name SubGraphRepresenation

##The subgraph this representation is a standin for
var subGraph : CardEditorSubGraph
##All the input options
@export var inputs : Array[GraphTypeSelector]
##All the output options
@export var outputs : Array[GraphTypeSelector]
var graphTypePrefab = load("res://Resources/SetEditor/GraphTypeSelector.tscn")

const TOP_TEXT_SIZE = 3

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
	subTypeSelector.attach_relay(subGraph, isInput)
	move_child(newTypeSelector, newIndex)
	newTypeSelector.attach_subgraph_rep(self, isInput)
	subTypeSelector.attach_subgraph_rep(self, isInput, newTypeSelector)
	update_shift_buttons()
	return newTypeSelector

##Removes a type selector of the given type
func remove_type_selector(toDeleteTypeSelector : GraphTypeSelector, isInput : bool):
	var portNum : int
	var delIndex : int = toDeleteTypeSelector.get_index()
	if isInput:
		portNum = inputs.find(toDeleteTypeSelector)
		inputs.erase(toDeleteTypeSelector)
		subGraph.graphIn.delete_entry(portNum, portNum)
	else:
		portNum = outputs.find(toDeleteTypeSelector)
		outputs.erase(toDeleteTypeSelector)
		subGraph.graphOut.delete_entry(portNum, portNum)
	delete_entry(delIndex, portNum)
	call_deferred("update_shift_buttons")

##Updates the typings on items when a new option is selected
func type_changed(_newType : int, source : GraphTypeSelector):
	if source in inputs:
		remove_connections(inputs.find(source))
		subGraph.graphIn.remove_connections(inputs.find(source))
	if source in outputs:
		remove_connections(outputs.find(source))
		subGraph.graphOut.remove_connections(outputs.find(source))
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
		subGraph.graphIn.get_child(inputIndex).update_shift_buttons(inputIndex, inputSize)
		var type = eachInput.optionButton.get_selected_id()
		update_slot_type(self, TOP_TEXT_SIZE + inputIndex, type, true)
		update_slot_type(subGraph.graphIn, inputIndex, type, false)
	subGraph.graphIn.clear_slot(inputSize)
	clear_slot(inputSize + 3)
	clear_slot(inputSize + 4)
	clear_slot(inputSize + 5)
	var outputOffset : int = TOP_TEXT_SIZE + inputSize + 3
	var outputSize = outputs.size()
	for outputIndex in outputSize:
		var eachOutput : GraphTypeSelector = outputs[outputIndex]
		eachOutput.update_shift_buttons(outputIndex, outputSize)
		subGraph.graphOut.get_child(outputIndex).update_shift_buttons(outputIndex, outputSize)
		var type = eachOutput.optionButton.get_selected_id()
		update_slot_type(self, outputOffset + outputIndex, type, false)
		update_slot_type(subGraph.graphOut, outputIndex, type, true)
	subGraph.graphOut.clear_slot(outputSize)
	clear_slot(outputOffset + outputSize)

func set_subgroup_name(newText: String) -> void:
	subGraph.emit_signal("name_changed", subGraph, newText)
