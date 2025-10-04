extends Node2D
class_name WorldMap

##The different map regions
class MapRegion:
	##Color of the Region
	var index : int
	##The sStars
	var aStar : AStarGrid2D
	##All coordinates that the map regions have
	var coords : PackedVector2Array
	
	const DIRS = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	
	##All the pips in this region
	var pips : Array[MapPip]
	
	func _init(nIndex : int, nCoords : PackedVector2Array) -> void:
		#Basic assignment
		index = nIndex
		coords.append_array(nCoords)
		#Get the AStarRect
		var aStarRegion := Rect2i(Vector2(999, 999), Vector2.ZERO)
		for eachCoord in coords:
			#The AStar Coords would start at the minimum coord
			aStarRegion.position = aStarRegion.position.min(eachCoord)
			#And end at the maximum coord
			aStarRegion.end = aStarRegion.end.max(eachCoord)
		#Add 1 to the end because it's gotta include itself
		aStarRegion.end += Vector2i.ONE
		#Create the AStar
		aStar = AStarGrid2D.new()
		aStar.region = aStarRegion
		aStar.cell_size = WorldMap.CELL_SIZE
		aStar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
		aStar.update()
		WorldMap.run_for_region(aStar.region, WorldMap.solidify_unfound_cells.bind(aStar, coords))
	
	##Get all the random coords you plan to use
	func rand_pip_coords(toPick : int) -> PackedVector2Array:
		var output := PackedVector2Array()
		var coordsNoDupes : Array = coords.duplicate()
		for i in toPick:
			#Pick a random spot
			var randCord : Vector2 = Persist.pick_random(coordsNoDupes)
			#Mark it as solid for pathfinding
			if aStar.is_in_boundsv(randCord):
				aStar.set_point_solid(randCord)
			else:
				push_warning("Point is not in bounds!")
			#Remove this coord and adjacent coords as possible spots
			coordsNoDupes.erase(randCord)
			for eachDir in DIRS:
				coordsNoDupes.erase(randCord + eachDir)
			output.append(randCord)
		return output

@export var mapRadius : int = 25
const CELL_SIZE = Vector2i(16, 16)
var aStar : AStarGrid2D
var regions : Array[MapRegion]

@export_category("Map Rendering")
@export var groundTilemap : TileMapLayer

@export_category("Pips and Paths")
@export var mapSpot : Node2D
@export var pipPrefab : PackedScene
@export var pathPrefab : PackedScene
@export var pips : Dictionary[Vector2i, MapPip]
@export var paths : Array[MapWalkPip]

func _ready() -> void:
	aStar = AStarGrid2D.new()
	var mapSize := Vector2i(mapRadius, mapRadius) * 2
	var startPoint : Vector2i = -mapSize / 2
	var centerRadius := mapRadius / (PI * 1.5)
	aStar.region = Rect2i(startPoint, mapSize)
	aStar.cell_size = CELL_SIZE
	aStar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	aStar.update()
	#Get all the regions coords
	var regionCoords = run_for_region(aStar.region, get_region_cell.bind(centerRadius), true)
	#Create the regions
	for regionIndex in regionCoords.keys():
		generate_region(regionIndex, regionCoords[regionIndex])
	#generate_paths()

##Construct a region
func generate_region(index : int, coords : PackedVector2Array):
	var newRegion := MapRegion.new(index, coords)
	regions.append(newRegion)
	groundTilemap.set_cells_terrain_connect(coords, index, 0)
	if index == 0:
		spawn_pip(-Vector2i.ONE, 0, MapPip.MapNodeType.BOSS)
		return
	var pipCoords := newRegion.rand_pip_coords(10)
	for eachCoord in pipCoords:
		var spawnCoord := eachCoord
		var nPip := spawn_pip(spawnCoord, index, MapPip.MapNodeType.ENEMY)
		newRegion.pips.append(nPip)

##Try to generate all paths in the world map
func generate_paths():
	for i in 1:
		#Get the current best goal
		var bestGoals : Array[MapWalkPip.ConnectionGoal] = []
		for eachPip in pips.values():
			eachPip = eachPip as MapPip
			bestGoals = eachPip.best_goal(bestGoals)
		#Create a path from it
		for eachGoal in bestGoals:
			solidify_path_goal(eachGoal)

##Get all the cells from the regions
func get_region_cell(cellX : int, cellY : int, centerRadius : float):
	var newCell := Vector2(cellX, cellY)
	var lineCentered := (newCell + (Vector2.ONE / 2))
	var cellDistance := lineCentered.length()
	#No cell here
	if cellDistance > mapRadius:
		return null
	#The center region
	if cellDistance <= centerRadius:
		return 0
	#Taking the angle and dividing it by PI/3 gives 6 wedges.
	#Flooring the value makes them in the right spot, addig 2 rotates it correctly
	#+6 % 6 assures all positive indexing, +1 skips the center tiles
	var point = (floori((lineCentered.angle() / (PI / 3)) + 2) + 6) % 6 + 1
	return point

##A Star
static func solidify_unfound_cells(cellX : int, cellY : int, inStar : AStarGrid2D, coords : PackedVector2Array):
	var coord := Vector2(cellX, cellY)
	inStar.set_point_solid(coord, coords.has(coord))
	return null

##Runs a callable for each cell, returnind a dictionary of results.
##Null results are disincluded.
static func run_for_region(inRect : Rect2i, callable : Callable, reverse : bool = false) -> Dictionary:
	var output := {}
	#For the XY of the region
	for cellX in range(inRect.position.x, inRect.end.x):
		for cellY in range(inRect.position.y, inRect.end.y):
			#Do the function
			var result = callable.call(cellX, cellY)
			#Remove null results
			if result == null:
				continue
			#Get the coord
			var coord := Vector2i(cellX, cellY)
			#Reverse it if asked
			if reverse:
				output = PD.append_dict_entry(output, result, coord)
			else:
				output[coord] = result
	return output

##Creates a pip at those coords, with the given region visuals and type
func spawn_pip(coords : Vector2i, region : int, type : MapPip.MapNodeType) -> MapPip:
	var newPip : MapPip = pipPrefab.instantiate()
	mapSpot.add_child(newPip)
	pips[coords] = newPip
	newPip.global_position = Vector2i(coords.x * CELL_SIZE.x, coords.y * CELL_SIZE.y) + (CELL_SIZE / 2)
	newPip.setup_pip(region, type)
	return newPip

##Creates an empty path to be constructed later
func spawn_path(point1 : MapPip, point2 : MapPip) -> MapWalkPip:
	var newPath : MapWalkPip = pathPrefab.instantiate()
	mapSpot.add_child(newPath)
	newPath.pathPoint1 = point1
	newPath.pathPoint2 = point2
	paths.append(newPath)
	newPath.create_pip_goals()
	return newPath

##Turns a path goal into actual path data
func solidify_path_goal(inGoal : MapWalkPip.ConnectionGoal):
	var pathDirs := inGoal.get_path_dirs()
	#Get the astar relevant to the region data
	var starForUse : AStarGrid2D
	var pathRegion := inGoal.path.region()
	match pathRegion:
		-1:
			starForUse = aStar
		-2:
			inGoal.path.generated = true
			inGoal.path.path_generated.emit()
			print("Warp Logic")
			return
		_:
			starForUse = regions[pathRegion].aStar
	if !inGoal.path.generate_path(pathDirs[0], pathDirs[1], starForUse):
		print("Out of bounds!")
		inGoal.path.generated = true
		inGoal.path.path_generated.emit()

##Checks if there's paths yet to be generated
func all_paths_generated():
	for eachPath in paths:
		if !eachPath.generated:
			return false
	return true
