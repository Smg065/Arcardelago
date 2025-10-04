extends AnimatedSprite2D
class_name MapPip

##The types of locations that show up in the overworld
enum MapNodeType {AUTO, INTERSECTION, ENEMY, BOSS, OBSTACLE, GATE, SHOP, TREASURE, PORTAL, RELEASER}
##The recolorable renderer for the center of the pip
var colorNode : AnimatedSprite2D
##The map color this node is part of.[br]
##0: White[br]
##1: Red[br]
##2: Green[br]
##3: Violet[br]
##4: Orange[br]
##5: Blue[br]
##6: Yellow
@export var colorIndex : int
##The location this map node is
@export var mapNodeType : MapNodeType
##If this node is marked as done
var defeated : bool

##Orthoginal Input Directions
enum Directions {UP, RIGHT, DOWN, LEFT}

##The direction you would press to leave this node
@export var pathDirs : Dictionary[Directions, MapWalkPip]

##The goals this map node has in connecting to others
var pathGoals : Array[MapWalkPip.ConnectionGoal]

##Sets the pip up to be rendered
func setup_pip(nColorIndex : int, nMapNodeType : int) -> void:
	colorIndex = nColorIndex
	mapNodeType = nMapNodeType as MapNodeType
	colorNode = $Color
	var colorAppend := ""
	match mapNodeType:
		#Append the boss info to the color if needed
		MapNodeType.BOSS:
			position += Vector2.ONE * 8
			play("BossRing")
			colorAppend = "Boss"
		MapNodeType.SHOP:
			play("ShopBack")
			colorAppend = "Shop"
		MapNodeType.TREASURE:
			play("TreasureBack")
			colorAppend = "Treasure"
		MapNodeType.GATE:
			play("GateBack")
			colorAppend = "Gate"
		#Intersections have no metal ring
		MapNodeType.INTERSECTION:
			self_modulate = Color.TRANSPARENT
		#Portals, releasers and obstacles use their own unique renders
		MapNodeType.PORTAL:
			self_modulate = Color.TRANSPARENT
			return
		MapNodeType.OBSTACLE:
			self_modulate = Color.TRANSPARENT
			return
		MapNodeType.RELEASER:
			self_modulate = Color.TRANSPARENT
			return
		#Auto has no rendering at all
		MapNodeType.AUTO:
			modulate = Color.TRANSPARENT
			return
		#Enemies
		_:
			play("default")
	set_anim_pip_color(colorAppend)
	#Don't animate if it's an intersection
	if mapNodeType == MapNodeType.INTERSECTION:
		colorNode.pause()

##Set the colored pip in the middle to a specific colored animation
func set_anim_pip_color(colorAppend : String):
	#Match the color index
	match colorIndex:
		1:
			colorNode.play("Red%sPip" % colorAppend)
		2:
			colorNode.play("Green%sPip" % colorAppend)
		3:
			colorNode.play("Violet%sPip" % colorAppend)
		4:
			colorNode.play("Orange%sPip" % colorAppend)
		5:
			colorNode.play("Blue%sPip" % colorAppend)
		6:
			colorNode.play("Yellow%sPip" % colorAppend)
		_:
			colorNode.play("White%sPip" % colorAppend)

##Mark this node as defeated/undefeated, along with connected atuos
func defeat(nDefeated : bool = true) -> void:
	#Set the new value
	defeated = nDefeated
	#Non-Auto tiles update the visual
	if mapNodeType != MapNodeType.AUTO:
		if defeated:
			modulate = Color.GRAY
		else:
			modulate = Color.WHITE
		if mapNodeType == MapNodeType.TREASURE:
			play("TreasureBackOpen")
			set_anim_pip_color("TreasureOpen")
		if mapNodeType == MapNodeType.GATE:
			play("GateBackOpen")
			set_anim_pip_color("GateOpen")
	#Tell the paths if they're usable
	for eachPath in pathDirs.values():
		eachPath.unlocked = nDefeated
		#Pass it along for auto nodes
		var otherPip : MapPip = eachPath.other_pip(self)
		if otherPip.mapNodeType == MapNodeType.AUTO:
			if otherPip.defeated != defeated:
				otherPip.defeat(nDefeated)

##Checks if you can defeat this node at all
func defeatable():
	return mapNodeType != MapNodeType.INTERSECTION and mapNodeType != MapNodeType.PORTAL

##Checks if you must defeat this node to travel over it
func defeat_to_traverse() -> bool:
	return mapNodeType == MapNodeType.ENEMY or mapNodeType == MapNodeType.BOSS or mapNodeType == MapNodeType.OBSTACLE or mapNodeType == MapNodeType.GATE or mapNodeType == MapNodeType.AUTO

##Get the opposting counterpart of a path. Only works if there's 2 paths.
func other_path(startingPath : MapWalkPip) -> MapWalkPip:
	var paths := pathDirs.values()
	if paths.size() != 2:
		push_error("%s has no 'other' path when there's %s paths!" % [name, paths.size()])
		return null
	if paths[0] == startingPath:
		return paths[1]
	return paths[0]

##Get any directions not taken up by a path
func available_directions() -> Array[Directions]:
	var allDirs : Array[Directions] = [
		Directions.UP,
		Directions.DOWN,
		Directions.LEFT,
		Directions.RIGHT
	]
	for eachDir in pathDirs.keys():
		allDirs.erase(eachDir)
	return allDirs

##TODO: Make Bosses Not Blow:tm:
func get_grid_entry_point(offsetDir : Directions) -> Vector2i:
	var inputOffset : Vector2i
	match offsetDir:
		Directions.UP:
			inputOffset = Vector2i.UP
		Directions.RIGHT:
			inputOffset = Vector2i.RIGHT
		Directions.DOWN:
			inputOffset = Vector2i.DOWN
		Directions.LEFT:
			inputOffset = Vector2i.LEFT
	return ((Vector2i(global_position) + (Vector2i.ONE * 8)) / 16) + inputOffset

##Get the best goal from this specific node
func best_goal(bestGoals : Array[MapWalkPip.ConnectionGoal]) -> Array[MapWalkPip.ConnectionGoal]:
	if pathGoals.size() == 0:
		return []
	for eachGoal in pathGoals:
		var result : Array[MapWalkPip.ConnectionGoal] = eachGoal.best_goal(bestGoals)
		#If both are the best, put it in the array
		if result.size() == 2:
			bestGoals.append(eachGoal)
		#If only one is the best, it's the new array to beat
		else:
			bestGoals = result
	return bestGoals

##Remove this goal from the node
func clear_goal(inGoal : MapWalkPip.ConnectionGoal, usedDir : Directions):
	if !pathGoals.has(inGoal):
		print("Doesn't Exist")
		print("Path Generated = " + str(inGoal.path.generated))
	#Remove the goal
	pathGoals.erase(inGoal)
	#Tell the other goals connected to it the direction given is no longer viable
	for eachGoal in pathGoals:
		eachGoal.dir_taken(usedDir)

##Runs when a path is generated that you have a goal around
func path_generated(inPath : MapWalkPip):
	#Clear it from being a path goal anymore
	for eachGoal in pathGoals.duplicate():
		if eachGoal.path == inPath:
			print("Erased a goal")
			pathGoals.erase(eachGoal)
