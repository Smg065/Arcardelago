extends Path2D
class_name MapWalkPip

##The start of the map path
@export var pathPoint1 : MapPip
##The end of the map path
@export var pathPoint2 : MapPip
##If the path has been marked as cleared
var unlocked : bool
##How the Map Pips line up on the X axis (Left, Aligned, Right)
var xAlign : AlignDir
##How the Map Pips line up on the Y axis (Above, Aligned, Below)
var yAlign : AlignDir
##If this path is a warp instead of a standard trail
var isWarp : bool

##If the path data has been generated
var generated : bool
##How much the aStar path weighs extra
const PATH_COST = 10.0

##The alignment of the map pips along this path
enum AlignDir {
	ALIGNED,
	STARTS_ABOVE,
	STARTS_RIGHT,
	STARTS_BELOW,
	STARTS_LEFT,
	DIAGONAL
	}

##Setup the path for generation later
func setup_path(nPathPoint1 : MapPip, nPathPoint2 : MapPip):
	pathPoint1 = nPathPoint1
	pathPoint1.pathCount += 1
	pathPoint2 = nPathPoint2
	pathPoint2.pathCount += 1
	get_alignments()

##The distance between the two map nodes
func distance() -> float:
	return pathPoint1.global_position.distance_to(pathPoint2.global_position)

##Inverts the given alignment direction
static func invert_align_dir(inAlign : AlignDir) -> AlignDir:
	match inAlign:
		AlignDir.STARTS_LEFT:
			return AlignDir.STARTS_RIGHT
		AlignDir.STARTS_RIGHT:
			return AlignDir.STARTS_LEFT
		AlignDir.STARTS_ABOVE:
			return AlignDir.STARTS_BELOW
		AlignDir.STARTS_BELOW:
			return AlignDir.STARTS_ABOVE
	return inAlign

##Get only the orthoginal direction from non-diagonal inputs
static func orthogilize(inXAlign : AlignDir, inYAlign : AlignDir) -> AlignDir:
	if inXAlign != AlignDir.ALIGNED and inYAlign != AlignDir.ALIGNED:
		return AlignDir.DIAGONAL
	if inXAlign == AlignDir.ALIGNED:
		return inYAlign
	return inXAlign

##Figure out how these nodes are aligned on the map
static func axis_alignment(point1 : float, point2 : float, isVert : bool) -> AlignDir:
	if is_equal_approx(point1, point2):
		return AlignDir.ALIGNED
	elif point1 > point2:
		if isVert:
			return AlignDir.STARTS_BELOW
		else:
			return AlignDir.STARTS_RIGHT
	if isVert:
		return AlignDir.STARTS_ABOVE
	else:
		return AlignDir.STARTS_LEFT

##Get the alignments of the two nodes
func get_alignments() -> Array[AlignDir]:
	xAlign = axis_alignment(pathPoint1.global_position.x, pathPoint2.global_position.x, false)
	yAlign = axis_alignment(pathPoint1.global_position.y, pathPoint2.global_position.y, true)
	return [xAlign, yAlign]

##Use the given directional goals to create the path's curves and map nodes inputs
func generate_path(usedAStar : AStarGrid2D, globalAStar : AStarGrid2D) -> bool:
	#The closest distanced point(s) are the ones to use.
	var closestDist := 9999
	var bestOffset1 : Array[Vector2i]
	var bestOffset2 : Array[Vector2i]
	
	#Notify if the node's a 2x2
	var isDouble1 : bool = pathPoint1.mapNodeType == MapPip.MapNodeType.BOSS
	var isDouble2 : bool = pathPoint2.mapNodeType == MapPip.MapNodeType.BOSS
	
	#Get the prefered movement direction
	for ofset1 in pathPoint1.available_directions(usedAStar != globalAStar):
		var thisEntry1 := ofset1 + pathPoint1.gridPoint
		for ofset2 in pathPoint2.available_directions(usedAStar != globalAStar):
			var thisEntry2 := ofset2 + pathPoint2.gridPoint
			var thisDist := thisEntry1.distance_squared_to(thisEntry2)
			#Equal distances are appended
			if is_equal_approx(closestDist, thisDist):
				bestOffset1.append(ofset1)
				bestOffset2.append(ofset2)
			#Better distances override it
			elif closestDist > thisDist:
				closestDist = thisDist
				bestOffset1 = [ofset1]
				bestOffset2 = [ofset2]
	
	if bestOffset1.size() == 0 or bestOffset2.size() == 0:
		print(pathPoint1.available_directions(usedAStar != globalAStar))
		print(pathPoint2.available_directions(usedAStar != globalAStar))
		print("One of the nodes has no available entries!")
		return false
	
	#Get the available entry points
	var input1 : Vector2i = Persist.pick_random(bestOffset1)
	var input2 : Vector2i = Persist.pick_random(bestOffset2)
	
	#Get the start and end of the grid path
	var start1 := pathPoint1.gridPoint + input1
	var start2 := pathPoint2.gridPoint + input2
	#Step in the input direction again if it's a boss (2x2)
	#And you're going down/right
	if isDouble1:
		if input1 == Vector2i.RIGHT or input1 == Vector2i.DOWN:
			start1 += input1
	if isDouble2:
		if input2 == Vector2i.RIGHT or input2 == Vector2i.DOWN:
			start2 += input2
	
	#If it's out of bounds, it failed
	if !usedAStar.region.has_point(start1) or !usedAStar.region.has_point(start2):
		print("Path that goes from %s to %s does not exist within %s to %s" % [start1,start2,usedAStar.region.position,usedAStar.region.end])
		return false
	
	#They're no longer available
	pathPoint1.register(input1, self)
	pathPoint2.register(input2, self)
	
	var starIds : Array[Vector2i] = usedAStar.get_id_path(start1, start2)
	var pathPoints : PackedVector2Array = usedAStar.get_point_path(start1, start2)
	
	#Note that these paths got a LOT more expensive
	for eachPoint in starIds:
		usedAStar.set_point_weight_scale(eachPoint, PATH_COST)
		globalAStar.set_point_weight_scale(eachPoint, PATH_COST)
	
	#Add the start and end
	pathPoints.insert(0, pathPoint1.global_position - Vector2(WorldMap.CELL_SIZE / 2))
	pathPoints.append(pathPoint2.global_position - Vector2(WorldMap.CELL_SIZE / 2))
	
	#Cleanup redundant points
	var lastDir = Vector2.ZERO
	var cleanupPoints : PackedVector2Array
	for pointIndex in range(1, pathPoints.size()):
		#Get the lines that make up the points
		var curDir := pathPoints[pointIndex].direction_to(pathPoints[pointIndex - 1])
		#If the two directions are the same
		if lastDir.is_equal_approx(curDir):
			cleanupPoints.append(pathPoints[pointIndex - 1])
		#Remember this
		lastDir = curDir
	#And erase them
	for eachPoint in cleanupPoints:
		pathPoints.erase(eachPoint)
	
	#Adjust the entry marks to be non-standard to the grid if it's a 2x2
	if isDouble1:
		var nudgeDir = Vector2.RIGHT
		if input1 == Vector2i.RIGHT or input1 == Vector2i.LEFT:
			nudgeDir = Vector2.DOWN
		nudgeDir *= Vector2(WorldMap.CELL_SIZE) / 2
		var lineDir := pathPoints[1].direction_to(pathPoints[2]).abs()
		pathPoints[1] += nudgeDir
		if lineDir.is_equal_approx(pathPoints[1].direction_to(pathPoints[0]).abs()):
			if pathPoints.size() > 3:
				pathPoints[2] += nudgeDir
	if isDouble2:
		var nudgeDir = Vector2.RIGHT
		if input2 == Vector2i.RIGHT or input2 == Vector2i.LEFT:
			nudgeDir = Vector2.DOWN
		nudgeDir *= Vector2(WorldMap.CELL_SIZE) / 2
		var lineDir := pathPoints[-2].direction_to(pathPoints[-3]).abs()
		pathPoints[-2] += nudgeDir
		if lineDir.is_equal_approx(pathPoints[1].direction_to(pathPoints[0]).abs()):
			if pathPoints.size() > 3:
				pathPoints[-3] += nudgeDir
	
	#Create the curve itself
	for eachPoint in pathPoints:
		curve.add_point(eachPoint + Vector2(WorldMap.CELL_SIZE / 2))
	
	#Make the visuals have this
	$PathVis.points = curve.get_baked_points()
	$PathVis.default_color = Persist.random_color(0, 1, .5, 1, .5, 1)
	
	#The path is made
	generated = true
	return true

##Get the opposing pip attached to this path
func other_pip(startPip : MapPip) -> MapPip:
	if pathPoint1 == startPip:
		return pathPoint2
	return pathPoint1

##Get the movement multiplier for the player to use
func move_dir(startPip : MapPip) -> int:
	if pathPoint1 == startPip:
		return 1
	return -1

##See if you can travel with this path or not
func can_travel(startPip : MapPip) -> bool:
	#You can always move on undefeatable tiles and defeated tiles
	if !startPip.defeat_to_traverse() or startPip.defeated:
		return true
	#Tiles that have yet to be defeated will only allow unlocked paths
	return unlocked

##Get the region the pips are in.[br]
##If they're in diffrent regions, mark -1 for adjacent, -2 for distant
func region() -> int:
	if pathPoint1.region != pathPoint2.region:
		#Adjacent
		if WorldMap.is_adjacent(pathPoint1.region, pathPoint2.region):
			return -1
		#Distant
		return -2
	#The region both nodes are in
	return pathPoint1.region
