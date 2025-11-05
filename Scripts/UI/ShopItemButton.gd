extends Button
class_name ShopItemButton

@export var itemInfo : ShopItemInfo
var cost : int
var isPurchased : bool
signal purchased

##Setup the shop item button
func setup_info(nItemInfo : ShopItemInfo, shopCallback : Callable):
	itemInfo = nItemInfo
	cost = itemInfo.price[Persist.difficulty]
	icon = itemInfo.icon
	tooltip_text = itemInfo.name
	text = "%sG" % cost
	purchased.connect(shopCallback)
	Persist.game.itemHandler.cash_updated.connect(update_clickable)
	update_clickable()

func update_clickable():
	disabled = isPurchased or cost > Persist.game.itemHandler.currentMoney

func pressed() -> void:
	if disabled:
		return
	purchased.emit(self)
	text = "SOLD"
	isPurchased = true
	disabled = true
