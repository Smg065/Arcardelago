extends Path2D
class_name MapWalkPip

enum PathType {DIRECT, ORTHOGONAL, CURVED}
@export var pathPoint1 : MapPip
@export var pathPoint2 : MapPip
@export var pathType : PathType

func _ready() -> void:
	connect_pips()

func connect_pips() -> void:
	var isDiagonal = not is_equal_approx(pathPoint1.global_position.x, pathPoint2.global_position.x) and not is_equal_approx(pathPoint1.global_position.y, pathPoint2.global_position.y)
	curve.add_point(pathPoint1.global_position)
	curve.add_point(pathPoint2.global_position)
	if isDiagonal:
		match pathType:
			PathType.ORTHOGONAL:
				curve.add_point(Vector2(pathPoint2.global_position.x, pathPoint1.global_position.y), Vector2.ZERO, Vector2.ZERO, 1)
			#PathType.CURVED:
			#	
	$PathVis.points = curve.get_baked_points()
