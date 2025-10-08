extends PathFollow2D
class_name OverworldPlayer

@export var curPath : MapWalkPip 
@export var curPip : MapPip
@export var enabled : bool
var moveDir : int = 0
const DIR_INPUTS : Dictionary[Vector2i, String] = {
	Vector2i.UP : "Up",
	Vector2i.RIGHT : "Right",
	Vector2i.DOWN : "Down",
	Vector2i.LEFT : "Left"}
const MOVE_SPEED = 64

func _process(delta: float) -> void:
	if !enabled:
		return
	if curPath == null:
		map_pip_logic()
	else:
		move_along_path(delta)

func map_pip_logic():
	#Look for movement inputs
	for moveIndex in curPip.pathDirs:
		var inputName := DIR_INPUTS[moveIndex].capitalize()
		if Input.is_action_pressed(inputName):
			if curPip.pathDirs[moveIndex].can_travel(curPip):
				set_path_goal(curPip.pathDirs[moveIndex])
				return
	#Look to try this location out
	if Input.is_action_just_pressed("ConfirmOverworld"):
		if curPip.defeatable():
			curPip.defeat()

func set_path_goal(nPath : MapWalkPip):
	curPath = nPath
	get_parent().remove_child(self)
	curPath.add_child(self)
	moveDir = curPath.move_dir(curPip)
	progress_ratio = 1 - move_progress()

func move_along_path(delta: float):
	#Move along until you reach the 'end' of the direction you're moving
	progress += delta * MOVE_SPEED * moveDir
	if is_equal_approx(progress_ratio, move_progress()):
		#On arrival, set this as your pip
		curPip = curPath.other_pip(curPip)
		match curPip.mapNodeType:
			#If you're an auto node, keep going here
			MapPip.MapNodeType.AUTO:
				set_path_goal(curPip.other_path(curPath))
			#If you're a warp, warp
			MapPip.MapNodeType.PORTAL:
				var warpPath := curPip.other_path(curPath)
				var warpPoint := warpPath.other_pip(curPip)
				var warpExitPath := warpPoint.other_path(warpPath)
				curPip = warpPoint
				set_path_goal(warpExitPath)
			_:
				curPath = null

func move_progress() -> float:
	return 0.5 + (moveDir / 2.0)

func set_current_pip(nPip : MapPip):
	curPip = nPip
	global_position = curPip.global_position
