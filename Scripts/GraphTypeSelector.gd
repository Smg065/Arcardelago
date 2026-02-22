extends HBoxContainer
class_name GraphTypeSelector

##Gives the name of this entry
@export var lineName : LineEdit
##Selects this entry type
@export var optionButton : OptionButton
##The button to remove this entry
@export var removeButton : Button
##Moves this entry up
@export var upIndex : Button
##Moves this entry down
@export var downIndex : Button

##Makes the pairings relay their information
func pair(other_selector : GraphTypeSelector):
	lineName.text_changed.connect(other_selector.set_text)
	other_selector.lineName.text_changed.connect(set_text)
	optionButton.item_selected.connect(other_selector.set_type)
	other_selector.optionButton.item_selected.connect(set_type)

##Sets the text of a line edit
func set_text(newText : String):
	lineName.text = newText

##Sets the type you've selected
func set_type(newIndex : int):
	optionButton.select(newIndex)

##Attach subgraph
func attach_subgraph_rep(subGraph : SubGraphRepresenation, isInput : bool, sourceGraphType : GraphTypeSelector = null):
	if sourceGraphType == null:
		sourceGraphType = self
	relay_type_options(subGraph.graph)
	removeButton.pressed.connect(subGraph.remove_type_selector.bind(sourceGraphType, isInput))
	if sourceGraphType == self != isInput:
		size_flags_horizontal = Control.SIZE_SHRINK_END
	optionButton.item_selected.connect(subGraph.type_changed)

##Attach relay
func attach_relay(graph : CardEditorSubGraph, isInput : bool):
	var graphNode : GraphNode
	if isInput:
		graphNode = graph.graphIn
	else:
		graphNode = graph.graphOut
	graphNode.add_child(self)

##Updates the shift buttons to the state they're allowed to be
func update_shift_buttons(entryPoint : int, listLength : int):
	upIndex.disabled = entryPoint <= 0
	downIndex.disabled = entryPoint >= listLength - 1

##Append the relays to the option buttons
func relay_type_options(graph : GraphEdit):
	for eachEntry in graph.type_names:
		optionButton.add_item(graph.type_names[eachEntry], eachEntry)
