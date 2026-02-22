extends GraphEdit
class_name CardEditorSubGraph

@export var rep : SubGraphRepresenation
const SUBGRAPH_REP = preload("res://Resources/SetEditor/SubgraphRep.tscn")
@export var graphIn : GraphNode
@export var graphOut : GraphNode

@warning_ignore("unused_signal")
signal name_changed(thisGraph : CardEditorSubGraph, newName : String)

##The tree item associated with this graph
var treeElement : TreeItem

func _ready() -> void:
	type_names = {
		0: "AP Info",
		1: "Effect",
		2: "Color",
		3: "",
		4: "Int",
		5: "String",
		6: "String Array",
		7: "Image",
	}

#Either reparents or creates a new subgraph representaion of this
func add_subgraph(subGraph : CardEditorSubGraph):
	if subGraph.rep == null:
		subGraph.rep = SUBGRAPH_REP.instantiate()
		subGraph.rep.graph = subGraph
		subGraph.build_relay_node(true)
		subGraph.build_relay_node(false)
	else:
		subGraph.rep.get_parent().remove_child(subGraph.rep)
	add_child(subGraph.rep)

##Builds an input or output graph node
func build_relay_node(isInput : bool) -> GraphNode:
	var newGN = GraphNode.new()
	newGN.resizable = true
	add_child(newGN)
	if isInput:
		newGN.title = "Input Relay"
		graphIn = newGN
	else:
		newGN.title = "Output Relay"
		graphOut = newGN
	return newGN

func construct_connection(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> Dictionary:
	return {
		"from_node" : from_node,
		"from_port" : from_port,
		"to_node" : to_node,
		"to_port" : to_port,
		"keep_alive" : false
	}

func connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	print("E")
	connections.append(construct_connection(from_node, from_port, to_node, to_port))

func disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	print("F")
	connections.erase(construct_connection(from_node, from_port, to_node, to_port))
