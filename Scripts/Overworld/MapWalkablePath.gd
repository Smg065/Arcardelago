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

signal path_generated

##The alignment of the map pips along this path
enum AlignDir {
	ALIGNED,
	STARTS_ABOVE,
	STARTS_RIGHT,
	STARTS_BELOW,
	STARTS_LEFT,
	DIAGONAL
	}

const INPUT_PREFS := {
	AlignDir.STARTS_ABOVE : {
		MapPip.Directions.UP : -1,
		MapPip.Directions.RIGHT : 0,
		MapPip.Directions.DOWN : 1,
		MapPip.Directions.LEFT : 0
	},
	AlignDir.STARTS_RIGHT : {
		MapPip.Directions.UP : 0,
		MapPip.Directions.RIGHT : -1,
		MapPip.Directions.DOWN : 0,
		MapPip.Directions.LEFT : 1
	},
	AlignDir.STARTS_BELOW : {
		MapPip.Directions.UP : 1,
		MapPip.Directions.RIGHT : 0,
		MapPip.Directions.DOWN : -1,
		MapPip.Directions.LEFT : 0
	},
	AlignDir.STARTS_LEFT : {
		MapPip.Directions.UP : 0,
		MapPip.Directions.RIGHT : 1,
		MapPip.Directions.DOWN : 0,
		MapPip.Directions.LEFT : -1
	}
}

##The connections that want to be created
class ConnectionGoal:
	##The path this node's a part of
	var pip : MapPip
	var path : MapWalkPip
	var pairedGoal : ConnectionGoal
	##A dictionary of scores given to your prefered input directions
	var dPrefs : Dictionary[int, Array]
	func _init(nPath : MapWalkPip, nPrefs : Dictionary[int, Array], nPip : MapPip) -> void:
		path = nPath
		dPrefs = nPrefs
		pip = nPip
	
	##Clears the connected goals from their pip and readies for path construction
	func get_path_dirs() -> Array[MapPip.Directions]:
		#Get the best direction prefrence arrays
		var tPosGoalDirs = dPrefs[get_best_prefs()]
		var oPosGoalDirs = pairedGoal.dPrefs[get_best_prefs()]
		#Decide on the best one from this array
		var tGoalDir : MapPip.Directions
		if tPosGoalDirs.size() > 1:
			#FINE, I'll USE RNG when there's really two good options I GUESS...
			tGoalDir = Persist.pick_random(tPosGoalDirs)
		else:
			#Otherwise, no RNG needed (whew)
			tGoalDir = tPosGoalDirs[0]
		var oGoalDir : MapPip.Directions
		if oPosGoalDirs.size() > 1:
			#Like I said. Using RNG. Behold.
			oGoalDir = Persist.pick_random(oPosGoalDirs)
		else:
			#It'll be nice to not need RNG for most of this
			oGoalDir = oPosGoalDirs[0]
		
		#This goal is no longer needed in the root map pip
		pip.clear_goal(self, tGoalDir)
		pairedGoal.pip.clear_goal(pairedGoal, oGoalDir)
		
		#Is this goal the path's start?
		if path.pathPoint1 == pip:
			#Then start with that direction
			return [tGoalDir, oGoalDir]
		#Otherwise, start with the other's direction
		return [oGoalDir, tGoalDir]
	
	##Get the highest scoring prefrences first
	func get_best_prefs() -> int:
		var keys : Array[int] = dPrefs.keys().duplicate()
		keys.sort()
		return keys[-1]
	
	##Compare 2 Goals, and either return one, or both of them
	func best_goal(otherGoals : Array[ConnectionGoal]) -> Array[ConnectionGoal]:
		#Skip calculations
		if otherGoals.has(self):
			return otherGoals
		if otherGoals.size() == 0:
			return [self]
		
		#Get the pref scores
		var oPrefScore := otherGoals[0].get_best_prefs() + otherGoals[0].pairedGoal.get_best_prefs()
		var tPrefScore := get_best_prefs() + pairedGoal.get_best_prefs()
		
		#Expect the highest score to continue to steamroll
		if oPrefScore > tPrefScore:
			return otherGoals
		#If not, check if you have the same score
		elif oPrefScore == tPrefScore:
			#Get the furthest path distance
			var oDist := otherGoals[0].path.distance()
			var tDist := path.distance()
			#Equal Aprox firs to account for float shenanigans
			if is_equal_approx(oDist, tDist):
				#Then
				otherGoals.append(self)
				return otherGoals
			#The other path is more likely to be larger
			elif oDist > tDist:
				return otherGoals
			#If it isn't, the new array starts with this as the standard
			return [self]
		#If all else fails, you're the new chosen one
		return [self]
	
	##Remove the input from the possible scoring metrics
	func dir_taken(dirTaken : MapPip.Directions):
		#Go over all the scores
		for eachKey in dPrefs.keys():
			#If the score has this direction, not anymore
			if dPrefs[eachKey].has(dirTaken):
				print("Erased the key %s" % dirTaken)
				dPrefs[eachKey].erase(dirTaken)
				#The reason we if it is to remove empty pref lists after
				if dPrefs[eachKey].size() == 0:
					print("Erased the score %s" % eachKey)
					dPrefs.erase(eachKey)

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

##Gets the priority of which directions should be used sooner and which ones later
static func priority_sort(dirs : Array[MapPip.Directions], inXAlign : AlignDir, inYAlign : AlignDir, invert := false) -> Dictionary[int, Array]:
	##A dictionary containing the same directions, with priority to higher numbers
	var output : Dictionary[int, Array]
	#Invert it if you're looking for the end priorities
	if invert:
		inXAlign = invert_align_dir(inXAlign)
		inYAlign = invert_align_dir(inYAlign)
	
	var orth := orthogilize(inXAlign, inYAlign)
	for eachDir in dirs:
		var dirScore : int
		if orth == AlignDir.DIAGONAL:
			#Above/Below Diagonal uses yAlign
			if eachDir == MapPip.Directions.UP or eachDir == MapPip.Directions.DOWN:
				dirScore = INPUT_PREFS[inYAlign][eachDir]
			#Left/Right Diagonal uses xAlign
			else:
				dirScore = INPUT_PREFS[inXAlign][eachDir]
		else:
			#The one axis is the only one that matters
			dirScore = INPUT_PREFS[orth][eachDir]
		#Either create the new catagory or append it to that
		if !output.has(dirScore):
			output[dirScore] = [eachDir]
		else:
			output[dirScore].append(eachDir)
	return output

##Get the alignments of the two nodes
func get_alignments() -> Array[AlignDir]:
	xAlign = axis_alignment(pathPoint1.global_position.x, pathPoint2.global_position.x, false)
	yAlign = axis_alignment(pathPoint1.global_position.y, pathPoint2.global_position.y, true)
	return [xAlign, yAlign]

##Create the goals the map node pips will refrence
func create_pip_goals() -> void:
	#Get the alignments
	get_alignments()
	
	#Get the spare directions
	var dirs1 := pathPoint1.available_directions()
	var dirs2 := pathPoint2.available_directions()
	
	#If they're fully taken, there's a problem at graph construction
	if dirs1.size() == 0:
		push_error(name + ": No spares at Path 1!")
	if dirs2.size() == 0:
		push_error(name + ": No spares at Path 2!")
	
	#Construct the two connection goals and pass them back
	var goal1 := ConnectionGoal.new(self, priority_sort(dirs1, xAlign, yAlign), pathPoint1)
	var goal2 := ConnectionGoal.new(self, priority_sort(dirs2, xAlign, yAlign, true), pathPoint2)
	
	#Flag the goal to be the other
	goal1.pairedGoal = goal2
	goal2.pairedGoal = goal1
	
	#Call back the goals
	pathPoint1.pathGoals.append(goal1)
	path_generated.connect(pathPoint1.path_generated.bind(self))
	pathPoint2.pathGoals.append(goal2)
	path_generated.connect(pathPoint2.path_generated.bind(self))

##Use the given directional goals to create the path's curves and map nodes inputs
func generate_path(input1 : MapPip.Directions, input2 : MapPip.Directions, aStars : AStarGrid2D) -> bool:
	#Get the start and end of the grid path
	var start1 := pathPoint1.get_grid_entry_point(input1)
	var start2 := pathPoint2.get_grid_entry_point(input2)
	
	#If it's out of bounds, it failed
	if !aStars.region.has_point(start1) or !aStars.region.has_point(start2):
		return false
	var starIds : Array[Vector2i] = aStars.get_id_path(start1, start2)
	var pathPoints : PackedVector2Array = aStars.get_point_path(start1, start2)
	
	#Note that these paths got a LOT more expensive
	for eachPoint in starIds:
		aStars.set_point_weight_scale(eachPoint, PATH_COST)
	
	#Start point always starts here
	curve.add_point(pathPoint1.global_position)
	for eachPoint in pathPoints:
		curve.add_point(eachPoint - Vector2(WorldMap.CELL_SIZE / 2))
	#End point always ends here
	curve.add_point(pathPoint2.global_position)
	$PathVis.points = curve.get_baked_points()
	
	#The path is made
	generated = true
	path_generated.emit()
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
	if pathPoint1.colorIndex != pathPoint2.colorIndex:
		#Always adjacent to the center of the map
		if pathPoint1.colorIndex == 0 or pathPoint2.colorIndex == 0:
			return -1
		#Get the region offset
		var regionOffset : int = abs(pathPoint1.colorIndex - pathPoint2.colorIndex)
		#If it's 1
		if regionOffset == 1:
			return -1
		#Red and yellow are adjacent
		if regionOffset == 5:
			return -1
		#If none of the above are true, it's distant
		return -2
	else:
		return pathPoint1.colorIndex
