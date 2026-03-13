extends GraphEdit
class_name CardEditorSubGraph

@export var rep : SubGraphRepresenation
const SUBGRAPH_REP = preload("res://Resources/SetEditor/SubgraphRep.tscn")
@export var graphIn : CEGNBase
@export var graphOut : CEGNBase

@warning_ignore("unused_signal")
signal name_changed(thisGraph : CardEditorSubGraph, newName : String)

##The tree item associated with this graph
var treeElement : TreeItem

func _ready() -> void:
	type_names = {
		99: "Any",
		0: "AP Info",
		1: "Effect",
		2: "Color",
		3: "Bool",
		4: "Int",
		5: "String",
		6: "String Array",
		7: "Image",
	}
	connection_request.connect(connect_node)
	disconnection_request.connect(disconnect_node)
	right_disconnects = true

##Either reparents or creates a new subgraph representaion of this
func add_subgraph(subGraph : CardEditorSubGraph):
	if subGraph.rep == null:
		subGraph.rep = SUBGRAPH_REP.instantiate()
		subGraph.rep.subGraph = subGraph
		subGraph.build_relay_node(true)
		subGraph.build_relay_node(false)
	else:
		subGraph.rep.get_parent().remove_child(subGraph.rep)
	add_child(subGraph.rep)

##Builds an input or output graph node
func build_relay_node(isInput : bool) -> GraphNode:
	var newGN = CEGNBase.new()
	newGN.resizable = true
	add_child(newGN)
	if isInput:
		newGN.title = "Input Relay"
		graphIn = newGN
	else:
		newGN.title = "Output Relay"
		graphOut = newGN
	return newGN
