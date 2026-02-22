extends PopupMenu
class_name GraphRightClickMenu

##An array containing all spawnable nodes
@export var allNodes : Array[PackedScene]
##The last tree you selected
var lastTree : TreeItem

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for nodeIndex in allNodes.size():
		var eachNode = allNodes[nodeIndex]
		add_item(eachNode.resource_path.get_basename().get_file(), nodeIndex)
	add_item("Subgraph", allNodes.size())

func on_pressed(id: int) -> void:
	var cge : CardGraphEditor = get_parent().get_parent()
	if id < allNodes.size():
		var newNode : GraphNode = allNodes[id].instantiate()
		cge.treeGraph[lastTree].add_child(newNode)
		newNode.position = position
	else:
		match id - allNodes.size():
			0:
				cge.create_graph(lastTree)
