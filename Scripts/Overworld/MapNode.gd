extends AnimatedSprite2D
class_name MapPip

##The types of locations that show up in the overworld
enum MapNodeType {AUTO, INTERSECTION, ENEMY, BOSS, OBSTACLE, GATE, SHOP, TREASURE, PORTAL, RELEASER, EVENT, HOME}
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
##The actual region the map node is from. -1 for unassigned
@export var region : int = -1
##The location this map node is
@export var mapNodeType : MapNodeType
##If this node is marked as done
var defeated : bool

##The direction you would press to leave this node
@export var pathDirs : Dictionary[Vector2i, MapWalkPip]
##The number of paths connected to this node
var pathCount : int
##The directions that can be used to plug into other locations
var availableDirs : Array[Vector2i]
##Directions that lead off the map
var nullDirs : Array[Vector2i]
##Directions that lead into a new region
var crossDirs : Dictionary[Vector2i, int]
##The point on the grid
var gridPoint : Vector2i
##Node info
var nodeInfo : Dictionary
##The depth into the region
var regionDepth : float

##Sets the pip up to be rendered as the type chosen
func set_pip_type(nColorIndex : int, nMapNodeType : MapNodeType) -> void:
	#Visuals first
	colorIndex = nColorIndex
	mapNodeType = nMapNodeType
	setup_visuals()

##Visuals of type setting
func setup_visuals():
	colorNode = $Color
	var colorAppend := ""
	match mapNodeType:
		#Append the boss info to the color if needed
		MapNodeType.BOSS:
			position += Vector2.ONE * 8
			play("BossRing")
			colorAppend = "Boss"
		#Reuse the shop sprite for now
		MapNodeType.HOME:
			play("ShopBack")
			colorAppend = "Shop"
		#Shop sprites
		MapNodeType.SHOP:
			play("ShopBack")
			colorAppend = "Shop"
		#Treasure sprites
		MapNodeType.TREASURE:
			play("TreasureBack")
			colorAppend = "Treasure"
		#Gate sprites
		MapNodeType.GATE:
			play("GateBack")
			colorAppend = "Gate"
		#Intersections have no metal ring
		MapNodeType.INTERSECTION:
			self_modulate = Color.TRANSPARENT
		#Portals, releasers and obstacles use their own unique renders
		MapNodeType.PORTAL:
			self_modulate = Color.TRANSPARENT
			colorNode.modulate = Color.BLACK
			return
		MapNodeType.OBSTACLE:
			self_modulate = Color.TRANSPARENT
			return
		MapNodeType.RELEASER:
			self_modulate = Color.TRANSPARENT
			colorNode.play("Altar")
			return
		#Auto has no rendering at all
		MapNodeType.AUTO:
			modulate = Color.TRANSPARENT
			return
		#Events have no metal ring
		MapNodeType.EVENT:
			play("EventBack")
			colorAppend = "Event"
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

##Generate the pip's direction availability
func direction_availability(worldMap : WorldMap):
	availableDirs.clear()
	nullDirs.clear()
	crossDirs.clear()
	for eachOffset in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		var entryPoint : Vector2 = gridPoint + eachOffset
		#If the entry of this node is not in-region
		if !worldMap.regions[region].coords.has(entryPoint):
			#Check if it's in ANY region
			for eachRegion in worldMap.regions:
				if eachRegion.coords.has(entryPoint):
					crossDirs[eachOffset] = eachRegion.index
					break
			if !crossDirs.has(eachOffset):
				nullDirs.append(eachOffset)
		else:
			availableDirs.append(eachOffset)

##Mark this node as defeated/undefeated, along with connected atuos
func defeat(nDefeated : bool = true) -> void:
	#Set the new value
	defeated = nDefeated
	#Obviously you can't really 'defeat' nodes that aren't defeatable
	if defeatable():
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
	match mapNodeType:
		MapNodeType.INTERSECTION:
			return false
		MapNodeType.TREASURE:
			return false
		MapNodeType.PORTAL:
			return false
		MapNodeType.HOME:
			return false
		MapNodeType.SHOP:
			return false
	return true

##Get the opposting counterpart of a path. Only works if there's 2 paths.
func other_path(startingPath : MapWalkPip) -> MapWalkPip:
	var paths := pathDirs.values()
	if paths.size() != 2:
		push_error("%s has no 'other' path when there's %s paths!" % [name, paths.size()])
		return null
	if paths[0] == startingPath:
		return paths[1]
	return paths[0]

##Flag if you've got more than 1 path that can connect
func connections_available(inRegion : bool = true) -> bool:
	#Nodes that can only connect to 2 paths max are unavailable after
	if pathCount >= 2:
		match mapNodeType:
			MapPip.MapNodeType.PORTAL:
				return false
			MapPip.MapNodeType.AUTO:
				return false
			MapPip.MapNodeType.GATE:
				return false
	#Otherwise, you need at least 1 path available
	return available_directions(inRegion).size() - pathCount > 0

##Get any directions not taken up by a path
func available_directions(inRegion : bool = true) -> Array[Vector2i]:
	var allDirs : Array[Vector2i] = availableDirs.duplicate()
	#Disclude directions already used
	for eachDir in pathDirs.keys():
		allDirs.erase(eachDir)
	#Erase directions that are fully nullified
	for eachDir in nullDirs:
		allDirs.erase(eachDir)
	#If you're a region-internal path, no cross-worlding
	if inRegion:
		for eachDir in crossDirs.keys():
			allDirs.erase(eachDir)
	if availableDirs.size() == 0:
		print("No available directions on this node!")
	return allDirs

##Set your global position to match the grid point, along with the region
func set_grid_point(nGridPoint : Vector2i, nRegion : int, worldMap : WorldMap):
	gridPoint = nGridPoint
	region = nRegion
	direction_availability(worldMap)
	global_position = (gridPoint * WorldMap.CELL_SIZE) + (WorldMap.CELL_SIZE / 2)

##Register a path to an input direction
func register(inputDir : Vector2i, path : MapWalkPip):
	pathDirs[inputDir] = path
	availableDirs.erase(inputDir)

##Calculates the Region Depth. Starts with In Region nodes called on Final Pip.
func recursive_depth_search(regionNodes : Array[MapPip], checkedPaths : Array[MapWalkPip] = [], currentDepth : int = 1) -> Dictionary:
	##The output pips to return
	var output : Dictionary = {}
	##The pips at this depth
	var nextPips : Array[MapPip]
	##Find all in-region pips that are at the end of unchecked paths
	for eachPath in pathDirs.values():
		if !checkedPaths.has(eachPath):
			checkedPaths.append(eachPath)
			nextPips.append(eachPath.other_pip(self))
	#Apply those nodes
	output[currentDepth] = nextPips
	#Recursion for each connected node
	for eachPip in nextPips:
		#Merge the info gotten from the next depths
		var toMerge := eachPip.recursive_depth_search(regionNodes, checkedPaths, currentDepth + 1)
		for mergeKeys in toMerge.keys():
			#If it's a new depth, just assign
			if !output.has(mergeKeys):
				output[mergeKeys] = toMerge[mergeKeys]
			#Otherwise, append the new array to this key
			else:
				output[mergeKeys].append_array(toMerge[mergeKeys])
	return output

##Construct the info for use
func build_info():
	nodeInfo["Region"] = region
	match mapNodeType:
		#No Data
		MapNodeType.AUTO:
			nodeInfo = {}
		MapNodeType.INTERSECTION:
			nodeInfo = {}
		#Cutscenes
		MapNodeType.OBSTACLE:
			nodeInfo["Type"] = "Obstacle"
			nodeInfo["Color"] = colorIndex
		MapNodeType.GATE:
			nodeInfo["Type"] = "Gate"
			nodeInfo["Color"] = colorIndex
		MapNodeType.PORTAL:
			nodeInfo["Type"] = "Portal"
		#Enemies
		MapNodeType.ENEMY:
			var battleInfo : BattleInfo = BattleInfo.new()
			nodeInfo["Type"] = "Enemy"
			battleInfo.region = region
			battleInfo.calculate_difficulty(regionDepth)
			nodeInfo["Info"] = battleInfo
		MapNodeType.BOSS:
			var battleInfo : BattleInfo = BattleInfo.new()
			nodeInfo["Type"] = "Enemy"
			battleInfo.region = region
			#If you're the boss of the spawning region, you're the first rival battle
			if Persist.spawnSphere == ((region - 1) as ColorCatagory.ColorTypes):
				battleInfo.type = BattleInfo.BattleType.RIVAL
			#The Final Boss
			elif region == 0:
				battleInfo.type = BattleInfo.BattleType.FINAL_BOSS
			else:
				battleInfo.type = BattleInfo.BattleType.BOSS
			nodeInfo["Info"] = battleInfo
		MapNodeType.SHOP:
			nodeInfo["Type"] = "Shop"
		MapNodeType.TREASURE:
			nodeInfo["Type"] = "Treasure"
		MapNodeType.RELEASER:
			nodeInfo["Type"] = "Releaser"
		MapNodeType.EVENT:
			nodeInfo["Type"] = "Event"
		MapNodeType.HOME:
			nodeInfo["Type"] = "Home"
