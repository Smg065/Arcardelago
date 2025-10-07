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
	
	#Start point always starts here
	curve.add_point(pathPoint1.global_position)
	for eachPoint in pathPoints:
		curve.add_point(eachPoint + Vector2(WorldMap.CELL_SIZE / 2))
	#End point always ends here
	curve.add_point(pathPoint2.global_position)
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

##If this path is a warp hint rather than being an actual path.
func is_warp() -> bool:
	if pathPoint1.mapNodeType == MapPip.MapNodeType.PORTAL:
		return pathPoint2.mapNodeType == MapPip.MapNodeType.PORTAL
	return false

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
