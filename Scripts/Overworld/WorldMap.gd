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
	##The pip the house/interregionals should start at
	var finalPip : MapPip
	##The region you came from
	var previousRegion : MapRegion
	##The regions you want to connect to
	var neighborRegions : Array[MapRegion]
	##Pips that are gates
	var gatePips : Array[MapPip]
	##The regions you warp to
	var warpRegions : Array[MapRegion]
	##Pips that are gates
	var warpPips : Array[MapPip]
	##If this end of the region has a gate
	var warpHasGate : Array[bool]
	##The sphere required to traverse this warp
	var warpSphere : PackedInt32Array
	
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
	func rand_pip_coords(toPick : int, aStarGlobal : AStarGrid2D) -> Dictionary:
		var output : Dictionary = {
			#"Boss" : Vector2,
			#"Home" : Vector2,
			"Gates" : PackedVector2Array(),
			"Warps" : PackedVector2Array(),
			"Random" : PackedVector2Array()
		}
		#Ignoring the furthest edge, get the 2nd ring in and all tiles center to that
		var coordsNoDupes := trim_edges(coords)
		#Get the boss spawn point
		var bossCoord : Vector2 = Persist.pick_random(trim_edges(coordsNoDupes["Center"])["Center"])
		output["Boss"] = bossCoord
		#Don't spawn on the boss node
		for eachOffset in [Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN, Vector2.DOWN + Vector2.RIGHT]:
			coordsNoDupes = block_point(bossCoord + eachOffset, coordsNoDupes, aStarGlobal)
		#If there's a home
		if Persist.spawnSphere + 1 == index:
			var homeCoord : Vector2 = Persist.pick_random(coordsNoDupes["Center"])
			output["Home"] = homeCoord
			coordsNoDupes = block_point(homeCoord, coordsNoDupes, aStarGlobal)
		
		#Get the adjacency spots
		for eachNeighbor in neighborRegions:
			#Only if it's within 1 tile of the bounding box
			var rect : Rect2i = Rect2i(eachNeighbor.aStar.region)
			var validEdges := rect_overlap_points(rect.grow(1), coordsNoDupes["Edge"])
			#Grab a random coord from that
			var randCord : Vector2 = Persist.pick_random(validEdges)
			coordsNoDupes = block_point(randCord, coordsNoDupes, aStarGlobal)
			output["Gates"].append(randCord)
		#Get the map warps
		for eachGateEnd in warpHasGate:
			var warpCoord : Vector2 = Persist.pick_random(coordsNoDupes["Center"])
			coordsNoDupes = block_point(warpCoord, coordsNoDupes, aStarGlobal)
			#Check if it's the gate end here
			if eachGateEnd:
				#Keep the warp and gate within 3 x/y of eachother
				var validGateCoords := rect_overlap_points(Rect2i(warpCoord, Vector2i.ZERO).grow(3), coordsNoDupes["Center"])
				var gateCoord : Vector2 = Persist.pick_random(validGateCoords)
				coordsNoDupes = block_point(gateCoord, coordsNoDupes, aStarGlobal)
				output["Gates"].append(gateCoord)
			output["Warps"].append(warpCoord)
		#Center tiles
		for i in toPick:
			#Pick a random spot
			var randCord : Vector2 = Persist.pick_random(coordsNoDupes["Center"])
			coordsNoDupes = block_point(randCord, coordsNoDupes, aStarGlobal)
			output["Random"].append(randCord)
		return output
	
	##Returns only the points that overlap with the rect
	static func rect_overlap_points(inRect : Rect2i, inPoints : PackedVector2Array) -> PackedVector2Array:
		var overlapPoints : PackedVector2Array
		for eachPoint in inPoints:
			if inRect.has_point(eachPoint):
				overlapPoints.append(eachPoint)
		return overlapPoints
	
	##Blocks a point during random coord choosing
	func block_point(newCoord, coordsNoDupes : Dictionary, aStarGlobal : AStarGrid2D) -> Dictionary:
		#Mark it as solid for pathfinding
		if aStar.is_in_boundsv(newCoord):
			aStar.set_point_solid(newCoord)
			aStarGlobal.set_point_solid(newCoord)
		else:
			push_warning("Point is not in bounds!")
		#Remove this coord and adjacent coords as possible spots
		coordsNoDupes["Center"].erase(newCoord)
		coordsNoDupes["Edge"].erase(newCoord)
		#Make adjacent tiles cost more to travel along
		for eachDir in DIRS:
			var adjacent : Vector2 = newCoord + eachDir
			if aStar.is_in_boundsv(adjacent):
				aStar.set_point_weight_scale(adjacent, 2)
			if aStarGlobal.is_in_boundsv(adjacent):
				aStarGlobal.set_point_weight_scale(adjacent, 2)
			coordsNoDupes["Center"].erase(newCoord + eachDir)
			coordsNoDupes["Edge"].erase(newCoord + eachDir)
		return coordsNoDupes
	
	##Trim all the edge coords from a coord list
	static func trim_edges(inCoords : PackedVector2Array) -> Dictionary[String, PackedVector2Array]:
		var output : Dictionary[String, PackedVector2Array] = {
			"Center" : PackedVector2Array(),
			"Edge" : PackedVector2Array()
		}
		for eachEntry in inCoords:
			var isEdge : bool = false
			for eachDir in DIRS:
				if !inCoords.has(eachEntry + eachDir):
					isEdge = true
					break
			#Edge Coords
			if isEdge:
				output["Edge"].append(eachEntry)
			#Center Coords
			else:
				output["Center"].append(eachEntry)
		return output
	
	##Get the target pip that leads to a region
	func get_interregional_pip(inRegion : MapRegion) -> MapPip:
		#Go over the neighbors to see if that's your index
		if neighborRegions.has(inRegion):
			return gatePips[neighborRegions.find(inRegion)]
		#Otherwise, go over the warps to see if that's your index instead
		if warpRegions.has(inRegion):
			return warpPips[warpRegions.find(inRegion)]
		#If all else fails, error
		push_error("No path from region %s to region %s!" % [index, inRegion.index])
		return null
	
@export var mapPlayer : OverworldPlayer
@export var diagonalMode : AStarGrid2D.DiagonalMode
const CELL_SIZE = Vector2i(16, 16)
var aStar : AStarGrid2D
var regions : Array[MapRegion]
var mapOrder : Dictionary[MapRegion, Array]

@export_category("Map Rendering")
@export var groundTilemap : TileMapLayer

@export_category("Pips and Paths")
@export var mapSpot : Node2D
@export var pipPrefab : PackedScene
@export var pathPrefab : PackedScene
@export var pips : Array[MapPip]
var homePip : MapPip

var nodesUsedPercents : Dictionary[String, float] = {
	"Auto":0,
	"Intersection":0,
	"Shop":0,
	"Treasure":0,
	"Releaser":0,
	"Warp":0,
	"Event":0,
	"Enemy":0
}
@export var paths : Array[MapWalkPip]

func _ready() -> void:
	aStar = AStarGrid2D.new()
	var mapSize := Vector2i(Persist.mapRadius, Persist.mapRadius) * 2
	var startPoint : Vector2i = -mapSize / 2
	var centerRadius := Persist.mapRadius / (PI * 1.5)
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
	create_interretiongal_connections()
	#Create the spawning nodes
	for eachRegion in regions:
		#Spawn the nodes
		spawn_region_nodes(eachRegion)
	#Generate the paths
	generate_all_paths()
	#Set the player at the home pip
	mapPlayer.set_current_pip(homePip)
	mapPlayer.enabled = true

##Construct a region
func generate_region(index : int, coords : PackedVector2Array):
	var newRegion := MapRegion.new(index, coords, diagonalMode)
	regions.append(newRegion)
	newRegion.draw_tiles(groundTilemap)

##Get a region by it's name
func get_region_by_name(inColor : String) -> MapRegion:
	return regions[ColorCatagory.COLOR_NAMES.find(inColor) + 1]

##Figure out how regions piece together
func create_interretiongal_connections():
	#Get the world order as a depth-first sorted dictionary
	var spawnName = ColorCatagory.BASE_COLORS[Persist.spawnSphere as int].name
	var dfsRegions := PD.depth_first_search(Persist.worldOrder, spawnName)
	var deepestRegions := PD.get_best(dfsRegions, PD.square_bracket.bind(dfsRegions))
	#Get the deepest node
	var semifinalRegion := get_region_by_name(Persist.pick_random(deepestRegions))
	semifinalRegion.neighborRegions.append(regions[0])
	regions[0].previousRegion = semifinalRegion
	#Mark bridges between regions that exist
	for eachColor in dfsRegions:
		#No gate of your spawn color
		if spawnName == eachColor:
			continue
		#Get the path you'd take to get to this sphere logically
		var path := PD.get_graph_path(Persist.worldOrder, spawnName, eachColor)
		#Get rid of your own entry because you're obviously in there
		path.erase(eachColor)
		#You CAN show up earlier
		var connectorOptions := []
		#The longer you go on the more times you roll to get the newest path node
		for eachOption in path:
			connectorOptions.append(Persist.pick_random(path))
		#Go for the one from the attepts selected that's the furthest along
		var deepestBridges := PD.get_best(connectorOptions, PD.square_bracket.bind(dfsRegions))
		var chosenBridge = Persist.pick_random(deepestBridges)
		#Connect them for node construction
		var startRegion = get_region_by_name(chosenBridge)
		var endRegion = get_region_by_name(eachColor)
		#Remember where you came from
		endRegion.previousRegion = startRegion
		#Walk across map boundries
		if is_adjacent(startRegion.index, endRegion.index):
			startRegion.neighborRegions.append(endRegion)
		else:
			#Which end has the gate is random
			var startHasGate : bool = Persist.rng.randi_range(0, 1) == 0
			#Warp Points Required
			startRegion.warpRegions.append(endRegion)
			startRegion.warpHasGate.append(startHasGate)
			startRegion.warpSphere.append(endRegion.index)
			endRegion.warpRegions.append(startRegion)
			endRegion.warpHasGate.append(!startHasGate)
			endRegion.warpSphere.append(endRegion.index)

##Create the nodes in a region
func spawn_region_nodes(inRegion : MapRegion):
	#Get the cooridnates for how many pips are needed in each region
	var rndNodeCount : int = 10
	if inRegion.index == 0:
		rndNodeCount = 1
	##If the house should spawn here instead of it connecting from another region
	var isRootRegion = Persist.spawnSphere + 1 == inRegion.index
	#Get a pool of available random types in the middle
	var typePool : Array[MapPip.MapNodeType]
	for spawnables in rndNodeCount:
		var nextType := get_next_pip_type()
		typePool.append(nextType)
		#Portals need to come in pairs
		if nextType == MapPip.MapNodeType.PORTAL:
			typePool.append(nextType)
	var pipCoords := inRegion.rand_pip_coords(typePool.size(), aStar)
	#Create the boss
	var bossPip := spawn_typed_pip(pipCoords["Boss"], inRegion.index, MapPip.MapNodeType.BOSS)
	inRegion.pips.append(bossPip)
	#Create all the gates
	var totalNeighbors := inRegion.neighborRegions.size()
	for eachIndex in pipCoords["Gates"].size():
		var eachCoord : Vector2 = pipCoords["Gates"][eachIndex]
		var gateColor : int
		#Pure neighbor regions first
		if totalNeighbors > eachIndex:
			gateColor = inRegion.neighborRegions[eachIndex].index
		#Followed by warp regions
		else:
			#The gate color has to take into acount preview warp zones
			gateColor = inRegion.warpSphere[eachIndex - totalNeighbors]
		var eachGate := spawn_typed_pip(eachCoord, gateColor, MapPip.MapNodeType.GATE, inRegion.index)
		inRegion.pips.append(eachGate)
		inRegion.gatePips.append(eachGate)
	#Create the interworld warps
	var gatedWarps : Array[MapPip]
	var ungatedWarps : Array[MapPip]
	for eachIndex in pipCoords["Warps"].size():
		var eachCoord : Vector2 = pipCoords["Warps"][eachIndex]
		var eachWarp := spawn_typed_pip(eachCoord, inRegion.index, MapPip.MapNodeType.PORTAL)
		inRegion.warpPips.append(eachWarp)
		#Connections to gates and warps must be considered
		if inRegion.warpHasGate[eachIndex]:
			var blockingGate := inRegion.gatePips[eachIndex + totalNeighbors]
			spawn_path(eachWarp, blockingGate)
			gatedWarps.append(eachWarp)
		else:
			ungatedWarps.append(eachWarp)
	
	#Create the random nodes between the others
	var randomPips : Array[MapPip]
	for eachCoord in pipCoords["Random"]:
		var spawnCoord : Vector2 = eachCoord
		var nPip := spawn_pip(spawnCoord, inRegion.index)
		inRegion.pips.append(nPip)
		randomPips.append(nPip)
	#Sort the randomized pips so they're a line leading to the boss
	randomPips = sort_map_pips(randomPips, bossPip)
	
	#Whatever the end point pip you have is what connects interregionals and the home
	inRegion.finalPip = randomPips[-1]
	 
	#Get all the nodes that occur before you travel interregionally
	var preInterregions : Array[MapPip]
	preInterregions.append_array(inRegion.gatePips)
	preInterregions.append_array(ungatedWarps)
	#Special case for the spawning sphere
	if isRootRegion:
		homePip = spawn_typed_pip(pipCoords["Home"], inRegion.index, MapPip.MapNodeType.HOME)
		spawn_path(homePip, inRegion.finalPip)
	else:
		#Otherwise, think about if the region leads to this one is generated
		if inRegion.previousRegion.index < inRegion.index:
			create_interregional_path(inRegion)
	
	#Backfill
	for eachRegion in regions:
		#Find the regions that declare you the previous one
		if eachRegion.previousRegion == inRegion:
			#If the previous region has been generated
			if eachRegion.index < inRegion.index:
				create_interregional_path(eachRegion)
	
	#Connect them to the closest one on the random path
	for eachGoal in preInterregions:
		var nearestPips := sort_map_pips(randomPips, eachGoal)
		var forUse : MapPip = null
		for eachRand in nearestPips:
			if eachRand.connections_available():
				forUse = eachRand
				break
		if forUse != null:
			spawn_path(forUse, eachGoal)
		else:
			push_warning("Absolutely Nothing Available for Path Connections!")
	
	#Figure out
	
	#TEMP: Linear Path
	var lastPip := bossPip
	for eachPip in randomPips:
		spawn_path(lastPip, eachPip)
		lastPip = eachPip

##Create the path that goes from one region to the next
func create_interregional_path(inRegion : MapRegion):
	#If it's been generated
	var startPip := inRegion.previousRegion.get_interregional_pip(inRegion)
	match startPip.mapNodeType:
		#Gates go to the final pip
		MapPip.MapNodeType.GATE:
			spawn_path(startPip, inRegion.finalPip)
		#Warps go to their respective warp
		MapPip.MapNodeType.PORTAL:
			spawn_path(startPip, inRegion.get_interregional_pip(inRegion.previousRegion))

##Create a pip type
func get_next_pip_type() -> MapPip.MapNodeType:
	#First, get the lowest usage values
	var tiedOptions : Array[String]
	tiedOptions.append_array(PD.get_best(nodesUsedPercents, PD.square_bracket.bind(nodesUsedPercents), true))
	#Then pick the ones with the highest rate of spawn
	var bestOptions : Array[String]
	bestOptions.append_array(PD.get_best(tiedOptions, PD.square_bracket.bind(Persist.nodePercents)))
	#The first one of the highest percent works
	var highestPercent : float = Persist.nodePercents[bestOptions[0]]
	#From the tied remaining, pick one at random
	var chosenType : String = Persist.pick_random(bestOptions)
	#Append the percent that it occurs
	nodesUsedPercents[chosenType] += 100.0 / highestPercent
	#Return the type based on the name
	match chosenType:
		"Auto":
			return MapPip.MapNodeType.AUTO
		"Intersection":
			return MapPip.MapNodeType.INTERSECTION
		"Shop":
			return MapPip.MapNodeType.SHOP
		"Treasure":
			return MapPip.MapNodeType.TREASURE
		"Releaser":
			return MapPip.MapNodeType.RELEASER
		"Warp":
			return MapPip.MapNodeType.PORTAL
		"Event":
			return MapPip.MapNodeType.EVENT
		_:
			if chosenType != "Enemy":
				push_warning(chosenType + "unknown; defaulted to 'Enemy'")
			return MapPip.MapNodeType.ENEMY

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
			if !inPath.is_warp():
				push_warning("2 Step Interregional that isn't a warp!")
				starForUse = aStar
			else:
				inPath.pathPoint1.register(Vector2i.ZERO, inPath)
				inPath.pathPoint2.register(Vector2i.ZERO, inPath)
				return
		#In-Region Mapping
		_:
			starForUse = regions[pathRegion].aStar
	if !inPath.generate_path(starForUse, aStar):
		print("No entries available! Path region claims %s" % pathRegion)
		inPath.generated = true

##Get all the cells from the regions
func get_region_cell(cellX : int, cellY : int, centerRadius : float):
	var newCell := Vector2(cellX, cellY)
	var lineCentered := (newCell + (Vector2.ONE / 2))
	var cellDistance := lineCentered.length()
	#No cell here
	if cellDistance > Persist.mapRadius:
		return null
	#The center region
	if cellDistance <= centerRadius:
		return 0
	#Taking the angle and dividing it by PI/3 gives 6 wedges.
	#Flooring the value makes them in the right spot, addig 2 rotates it correctly
	#+6 % 6 assures all positive indexing, +1 skips the center tiles
	var point = (floori((lineCentered.angle() / (PI / 3)) + 2) + 6) % 6 + 1
	return point

##A Star blockout the corners of circles
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

##Creates a pip at the given coords with the given region
func spawn_pip(coords : Vector2i, region : int) -> MapPip:
	var newPip : MapPip = pipPrefab.instantiate()
	mapSpot.add_child(newPip)
	pips.append(newPip)
	newPip.set_grid_point(coords, region, self)
	return newPip

##Creates a pip at the given coords, with the given region visuals and type
func spawn_typed_pip(coords : Vector2i, color : int, type : MapPip.MapNodeType, region : int = -1) -> MapPip:
	#Most of the time, the region is the color
	if region == -1:
		region = color
	#Instantiate
	var newPip : MapPip = spawn_pip(coords, region)
	#Give the setup data
	newPip.set_pip_type(color, type)
	return newPip

##Creates an empty path to be constructed later
func spawn_path(point1 : MapPip, point2 : MapPip) -> MapWalkPip:
	var newPath : MapWalkPip = pathPrefab.instantiate()
	mapSpot.add_child(newPath)
	newPath.setup_path(point1, point2)
	paths.append(newPath)
	return newPath

##Map node sorter to make the paths less complex/more straight
static func sort_map_pips(toSort : Array[MapPip], startingPip : MapPip) -> Array[MapPip]:
	var sortedPips : Array[MapPip]
	var originalPips : Array[MapPip]
	originalPips.append_array(toSort)
	originalPips.erase(startingPip)
	var previousPip := startingPip
	while originalPips.size() > 0:
		var closestPips : Array[MapPip] 
		closestPips.append_array(PD.get_best(originalPips, func(a, b : Vector2 = previousPip.global_position): return a.global_position.distance_squared_to(b), true))
		previousPip = Persist.pick_random(closestPips)
		originalPips.erase(previousPip)
		sortedPips.append(previousPip)
	return sortedPips

##See if two regions are adjacent or not
static func is_adjacent(regIndex1 : int, regIndex2 : int):
	#Always adjacent to the center of the map
	if regIndex1 == 0 or regIndex2 == 0:
		return true
	#Get the region offset
	var regionOffset : int = abs(regIndex1 - regIndex2)
	#If it's 1
	if regionOffset == 1:
		return true
	#Red and yellow are adjacent
	if regionOffset == 5:
		return true
	#If none of the above are true, it's distant
	return false
