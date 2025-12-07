extends Button
class_name MultiItemButton

@export var itemInfo : ItemInfo
var copies : int

##Setup the shop item button
func setup_info(nItemInfo : ItemInfo, callback : Callable):
	itemInfo = nItemInfo
	icon = nItemInfo.icon
	tooltip_text = "%s x%x" % [itemInfo.name, copies]
	text = "%s x%x" % [itemInfo.name, copies]
	pressed.connect(callback.bind(self))
