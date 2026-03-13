extends GraphNode
class_name CEGNBase

##The graph this is a child of
var graph : CardEditorSubGraph
##The colors of the node typings
const COLOR_BY_TYPE = {0:Color("767ebd"),1:Color("75c274"),2:Color("ffffff"),
3:Color("aa4499"),4:Color("c97582"),5:Color("eee391"),6:Color("c994c2"),
7:Color("d8a07d"),99:Color.BLACK}

func _ready() -> void:
	if graph == null:
		graph = get_parent()

##Removes all connections to a specific port
func remove_connections(portNum : int) -> void:
	var removeEntries : PackedInt64Array
	for conIndex in graph.connections.size():
		var eachCon : Dictionary = graph.connections[conIndex]
		if name == eachCon.from_node:
			if portNum == eachCon.from_port:
				removeEntries.append(conIndex)
		if name == eachCon.to_node:
			if portNum == eachCon.to_port:
				removeEntries.append(conIndex)
	removeEntries.reverse()
	for eachEntry in removeEntries:
		var conInfo : Dictionary = graph.connections[eachEntry]
		graph.disconnect_node(conInfo.from_node, conInfo.from_port, conInfo.to_node, conInfo.to_port)

##Deletes a port and shifts all entries to account for the removed port
func delete_entry(toDelete : int, portNum : int) -> void:
	var removeEntries : PackedInt64Array
	var fromDeindexEntries : PackedInt64Array
	var toDeindexEntries : PackedInt64Array
	for conIndex in graph.connections.size():
		var eachCon : Dictionary = graph.connections[conIndex]
		if name == eachCon.from_node:
			if portNum < eachCon.from_port:
				fromDeindexEntries.append(conIndex)
			elif portNum == eachCon.from_port:
				removeEntries.append(conIndex)
		if name == eachCon.to_node:
			if portNum < eachCon.to_port:
				toDeindexEntries.append(conIndex)
			elif portNum == eachCon.to_port:
				removeEntries.append(conIndex)
	removeEntries.reverse()
	for eachEntry in fromDeindexEntries:
		var conInfo : Dictionary = graph.connections[eachEntry]
		graph.disconnect_node(conInfo.from_node, conInfo.from_port, conInfo.to_node, conInfo.to_port)
		graph.connect_node(conInfo.from_node, conInfo.from_port - 1, conInfo.to_node, conInfo.to_port)
	for eachEntry in toDeindexEntries:
		var conInfo : Dictionary = graph.connections[eachEntry]
		graph.disconnect_node(conInfo.from_node, conInfo.from_port, conInfo.to_node, conInfo.to_port)
		graph.connect_node(conInfo.from_node, conInfo.from_port, conInfo.to_node, conInfo.to_port - 1)
	for eachEntry in removeEntries:
		var conInfo : Dictionary = graph.connections[eachEntry]
		graph.disconnect_node(conInfo.from_node, conInfo.from_port, conInfo.to_node, conInfo.to_port)
	var deleteNode : Node = get_child(toDelete)
	deleteNode.queue_free()
	remove_child(deleteNode)

##Swaps the index of two ports, by the shift direction. Only supports steps of 1.
func shift_entry(toShift : int, shiftDir : int) -> void:
	move_child(get_child(toShift), toShift + shiftDir)
	for eachCon in graph.connections:
		if name == eachCon.from_node:
			if toShift == eachCon.from_port:
				eachCon.from_port += shiftDir
			elif toShift + shiftDir == eachCon.from_port:
				eachCon.from_port -= shiftDir
		if name == eachCon.to_node:
			if toShift == eachCon.to_port:
				eachCon.to_port += shiftDir
			elif toShift + shiftDir == eachCon.to_port:
				eachCon.to_port -= shiftDir

##Sets the slot type in a given position
func update_slot_type(targetGraph : GraphNode, index : int, type : int, isInput : bool):
	targetGraph.set_slot(index, isInput, type, COLOR_BY_TYPE[type], !isInput, type, COLOR_BY_TYPE[type])
