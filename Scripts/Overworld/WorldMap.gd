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
	var noise : FastNoiseLite
	
	const DIRS = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT,
	Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	
	##All the pips in this region
	var pips : Array[MapPip]
	
	func _init(nIndex : int, nCoords : PackedVector2Array, diagonalMode : AStarGrid2D.DiagonalMode) -> void:
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
		
		#End is not considered in bounds, so bump it by 1
		aStarRegion.end += Vector2i.ONE
		
		#Create the AStar
		aStar = AStarGrid2D.new()
		aStar.region = aStarRegion
		aStar.cell_size = WorldMap.CELL_SIZE
		aStar.diagonal_mode = diagonalMode
		aStar.update()
		#print("Region %s goes from %s to %s" % [index, aStar.region.position, aStar.region.end])
		WorldMap.run_for_region(aStar.region, WorldMap.solidify_unfound_cells.bind(aStar, coords))
		
		#Create the noise for water/walls
		noise = FastNoiseLite.new()
		noise.seed = Persist.rng.randi()
		#noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		#noise.TYPE_SIMPLEX_SMOOTH
		noise.frequency = .05
	
	##Render the tiles using the noise map
	func draw_tiles(groundTilemap : TileMapLayer) -> void:
		var floorCoords : PackedVector2Array
		var wallCoords : PackedVector2Array
		var waterCoords : PackedVector2Array
		for eachCoord in coords:
			var noiseVal : float = noise.get_noise_2dv(eachCoord)
			if noiseVal < -0.25:
				waterCoords.append(eachCoord)
			elif noiseVal > 0.25:
				wallCoords.append(eachCoord)
			else:
				floorCoords.append(eachCoord)
		groundTilemap.set_cells_terrain_connect(floorCoords, index, 0)
		groundTilemap.set_cells_terrain_connect(wallCoords, index, 1)
		groundTilemap.set_cells_terrain_connect(waterCoords, index, 2)
	
	##Get all the random coords you plan to use
	func rand_pip_coords(toPick : int, aStarGlobal : AStarGrid2D) -> PackedVector2Array:
		var output := PackedVector2Array()
		var coordsNoDupes : Array = coords.duplicate()
		for i in toPick:
			#Pick a random spot
			var randCord : Vector2 = Persist.pick_random(coordsNoDupes)
			#Mark it as solid for pathfinding
			if aStar.is_in_boundsv(randCord):
				aStar.set_point_solid(randCord)
				aStarGlobal.set_point_solid(randCord)
			else:
				push_warning("Point is not in bounds!")
			#Remove this coord and adjacent coords as possible spots
			coordsNoDupes.erase(randCord)
			#Make adjacent tiles cost more to travel along
			for eachDir in DIRS:
				var adjacent : Vector2 = randCord + eachDir
				if aStar.is_in_boundsv(adjacent):
					aStar.set_point_weight_scale(adjacent, 2)
				if aStarGlobal.is_in_boundsv(adjacent):
					aStarGlobal.set_point_weight_scale(adjacent, 2)
				coordsNoDupes.erase(randCord + eachDir)
			output.append(randCord)
		return output
	

@export var mapRadius : int = 25
@export var mapPlayer : OverworldPlayer
@export var diagonalMode : AStarGrid2D.DiagonalMode
const CELL_SIZE = Vector2i(16, 16)
var aStar : AStarGrid2D
var regions : Array[MapRegion]

@export_category("Map Rendering")
@export var groundTilemap : TileMapLayer

@export_category("Pips and Paths")
@export var mapSpot : Node2D
@export var pipPrefab : PackedScene
@export var pathPrefab : PackedScene
@export var pips : Array[MapPip]
var finalBossPip : MapPip
@export var paths : Array[MapWalkPip]

func _ready() -> void:
	
	aStar = AStarGrid2D.new()
	var mapSize := Vector2i(mapRadius, mapRadius) * 2
	var startPoint : Vector2i = -mapSize / 2
	var centerRadius := mapRadius / (PI * 1.5)
	aStar.region = Rect2i(startPoint, mapSize)
	aStar.cell_size = CELL_SIZE
	aStar.diagonal_mode = diagonalMode
	aStar.update()
	#Get all the regions coords
	var regionCoords = run_for_region(aStar.region, get_region_cell.bind(centerRadius), true)
	#Create the regions
	for regionIndex in regionCoords.keys():
		generate_region(regionIndex, regionCoords[regionIndex])
	#Make the regions show up in order
	regions.sort_custom(func(a, b): return a.index < b.index)
	#For each region, do the following
	var startPip : MapPip = finalBossPip
	for eachRegion in regions:
		spawn_region_nodes(eachRegion)
		eachRegion.pips = sort_map_pips(eachRegion.pips, startPip)
	#Make it perfectly linear
	spawn_all_paths()
	#Generate the paths
	generate_all_paths()
	mapPlayer.set_current_pip(Persist.pick_random(pips))
	mapPlayer.enabled = true

##Construct a region
func generate_region(index : int, coords : PackedVector2Array):
	var newRegion := MapRegion.new(index, coords, diagonalMode)
	regions.append(newRegion)
	newRegion.draw_tiles(groundTilemap)
	#The center region has special spawning rules
	if index == 0:
		finalBossPip = spawn_pip(-Vector2i.ONE, 0, MapPip.MapNodeType.BOSS)
		return

##Create the nodes in a region
func spawn_region_nodes(inRegion : MapRegion):
	#Get the cooridnates for how many pips are needed in this region
	var pipCoords := inRegion.rand_pip_coords(10, aStar)
	for eachCoord in pipCoords:
		var spawnCoord := eachCoord
		var nPip := spawn_pip(spawnCoord, inRegion.index, 2 as MapPip.MapNodeType)
		inRegion.pips.append(nPip)

##Try to generate all paths in the world map
func generate_all_paths():
	for eachPath in paths:
		generate_path(eachPath)

##Turns a path goal into actual path data
func generate_path(inPath : MapWalkPip):
	#Get the astar relevant to the region data
	var starForUse : AStarGrid2D
	var pathRegion := inPath.region()
	match pathRegion:
		#Adjacent Mapping
		-1:
			starForUse = aStar
		#Create 2 warp points and bridge
		-2:
			inPath.generated = true
			print("Warp Logic")
			return
		#In-Region Mapping
		_:
			starForUse = regions[pathRegion].aStar
	if !inPath.generate_path(starForUse, aStar):
		print("No entries available!")
		inPath.generated = true

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
	inStar.set_point_solid(coord, !coords.has(coord))
	return null

##Runs a callable for each cell, returnind a dictionary of results.[br]
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
	pips.append(newPip)
	newPip.set_grid_point(coords)
	newPip.setup_pip(region, type, self)
	return newPip

##Creates an empty path to be constructed later
func spawn_path(point1 : MapPip, point2 : MapPip) -> MapWalkPip:
	var newPath : MapWalkPip = pathPrefab.instantiate()
	mapSpot.add_child(newPath)
	newPath.pathPoint1 = point1
	newPath.pathPoint2 = point2
	paths.append(newPath)
	newPath.get_alignments()
	return newPath

##Checks if there's paths yet to be generated
func all_paths_generated():
	for eachPath in paths:
		if !eachPath.generated:
			return false
	return true

##Map node sorter to make the paths less complex/more straight
static func sort_map_pips(toSort : Array[MapPip], startingPip : MapPip) -> Array[MapPip]:
	var sortedPips : Array[MapPip]
	var originalPips : Array[MapPip]
	originalPips.append_array(toSort)
	originalPips.erase(startingPip)
	var previousPip := startingPip
	while originalPips.size() > 0:
		var bestDist := 99999999999.9
		var closestPips : Array[MapPip]
		for eachPip in originalPips:
			var dist := eachPip.global_position.distance_squared_to(previousPip.global_position)
			if is_equal_approx(bestDist, dist):
				closestPips.append(eachPip)
			elif bestDist > dist:
				closestPips = [eachPip]
				bestDist = dist
		previousPip = Persist.pick_random(closestPips)
		originalPips.erase(previousPip)
		sortedPips.append(previousPip)
	return sortedPips

##Just go in total order
func spawn_all_paths():
	for eachRegion in regions:
		var lastPip := eachRegion.pips[0]
		for pipIndex in range(1, eachRegion.pips.size()):
			var thisPip := eachRegion.pips[pipIndex]
			spawn_path(lastPip, thisPip)
			lastPip = thisPip
