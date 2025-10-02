extends AnimatedSprite2D
class_name MapPip

enum MapNodeType {INTERSECTION, ENEMY, BOSS, OBSTACLE, SHOP, PORTAL, RELEASER}
var colorNode : AnimatedSprite2D
@export var colorIndex : int
@export var mapNodeType : MapNodeType
var defeated : bool

func _ready() -> void:
	colorNode = $Color
	var colorAppend := ""
	mapNodeType = randi_range(0,6) as MapNodeType
	colorIndex = randi_range(0,6)
	match mapNodeType:
		#Append the boss info to the color if needed
		MapNodeType.BOSS:
			position += Vector2.ONE * 8
			play("BossRing")
			colorAppend = "Boss"
		MapNodeType.SHOP:
			play("ShopBack")
			colorAppend = "Shop"
		#Intersections have no metal ring
		MapNodeType.INTERSECTION:
			self_modulate = Color.TRANSPARENT
		#Portals and obstacles use their own unique renders
		MapNodeType.PORTAL:
			self_modulate = Color.TRANSPARENT
			return
		MapNodeType.OBSTACLE:
			self_modulate = Color.TRANSPARENT
			return
		#Enemies, Shops, and Releasers
		_:
			play("default")
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
	#Don't animate if it's an intersection
	if mapNodeType == MapNodeType.INTERSECTION:
		colorNode.pause()

func defeat(nDefeated : bool = true):
	defeated = nDefeated
	if defeated:
		modulate = Color.GRAY
	else:
		modulate = Color.WHITE
