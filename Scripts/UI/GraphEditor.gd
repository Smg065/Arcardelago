extends HSplitContainer
class_name CardGraphEditor

##A map that relays what graph is being represtented by a tree item
var treeGraph : Dictionary[TreeItem, CardEditorSubGraph]
##The root tree item
var root : TreeItem

const SUBGRAPH_ICON = preload("res://Sprites/Edit.png")
const SUBGRAPH_PREFAB = preload("res://Resources/SetEditor/SubgraphRep.tscn")
const APINFO_PREFAB = preload("res://Resources/GraphEditor/ApInfo.tscn")

@export var tree : Tree
@export var subGraphContainer : MarginContainer
@export var rightClickMenu : GraphRightClickMenu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	root = create_graph()
	treeGraph[root].show()

#Creates a new Tree Item and Graph pairing
func create_graph(parent : TreeItem = null, index: int = -1) -> TreeItem:
	var nItem := tree.create_item(parent, index)
	treeGraph[nItem] = CardEditorSubGraph.new()
	treeGraph[nItem].hide()
	treeGraph[nItem].gui_input.connect(subgraph_right_click.bind(nItem))
	nItem.add_button(0, SUBGRAPH_ICON)
	subGraphContainer.add_child(treeGraph[nItem])
	if parent != null:
		#The parent should have a graph node representing the subgraph
		treeGraph[parent].add_subgraph(treeGraph[nItem])
	else:
		treeGraph[nItem].add_child(APINFO_PREFAB.instantiate())
	treeGraph[nItem].name_changed.connect(set_subgroup_name)
	return nItem

#Changes the name of the card set
func set_name_changed(newText: String) -> void:
	root.set_text(0, newText)

##Changes the name of the subgroup
func set_subgroup_name( subGraph : CardEditorSubGraph, newText: String):
	var treeItem = treeGraph.keys()[treeGraph.values().find(subGraph)]
	treeItem.set_text(0, newText)

##Sets the current graph to show to this element
func set_current_graph(treeItem : TreeItem):
	for eachTreeItem in treeGraph:
		treeGraph[eachTreeItem].visible = eachTreeItem == treeItem

func tree_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	match id:
		0:
			set_current_graph(item)

func subgraph_right_click(event: InputEvent, treeItem : TreeItem) -> void:
	if event is InputEventMouseButton:
		#Right click
		if event.button_index == 2 and not event.pressed:
			rightClickMenu.position = event.global_position
			rightClickMenu.lastTree = treeItem
			rightClickMenu.show()
