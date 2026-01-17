extends CardTagFilterBase
class_name CardTagFilterColor

const ITEM_LOOKUP : Dictionary[String, int] = {
	#Filler
	"Default Card"    : 0b000000,
	#Useful
	"Steel Stamp"     : 0b000001,
	"Harmony Stamp"   : 0b000010,
	"Ghost Stamp"     : 0b001000,
	"Square Stamp"    : 0b010000,
	"Gold Stamp"      : 0b100000,
	"House Upgrade"   : 0b000100,
	#Progression
	"Bottle"          : 0b000001,
	"Axe"             : 0b000010,
	"Castle Key"      : 0b000100,
	"Pickaxe"         : 0b001000,
	"Boat"            : 0b010000,
	"Shovel"          : 0b100000,
	#Proguseful
	"Red Sphere"      : 0b000001,
	"Green Sphere"    : 0b000010,
	"Violet Sphere"   : 0b000100,
	"Orange Sphere"   : 0b001000,
	"Blue Sphere"     : 0b010000,
	"Yellow Sphere"   : 0b100000,
	#Traps
	"Unstable Trap"   : 0b000001,
	"Fog Trap"        : 0b000010,
	"Release Trap"    : 0b000100,
	"Trade Down Trap" : 0b001000,
	"Stackless Trap"  : 0b010000,
	"Blind Trap"      : 0b100000
}

##Checks if the color data from this entry passes
func filter_passes(input, args : Dictionary) -> bool:
	#Validate argument expectations
	if !super(input, args):
		return false
	#Validate the incoming type
	for eachType in filterTypes:
		if validate_type(eachType, input):
			match eachType:
				FilterTypes.CARD:
					return card_filter(input, args) != args.invert
				FilterTypes.NODE:
					return pip_filter(input, args) != args.invert
				FilterTypes.ITEMS | FilterTypes.INSTANTS | FilterTypes.EVENTS:
					input = input as String
					if not input in ITEM_LOOKUP:
						return false
					return (ITEM_LOOKUP[input] == args.colorFlags) != args.invert
				FilterTypes.INCOME_SOURCE:
					match input["Type"]:
						"Sold":
							return card_filter(input["CardData"], args) != args.invert
						"Battle":
							return pip_filter(input["Pip"], args) != args.invert
				FilterTypes.PURCHASABLES:
					if "CardData" in input:
						return card_filter(input["CardData"], args) != args.invert
					if "ShopItem" in input:
						var shopItemName : String = input["ShopItem"].name
						if not shopItemName in ITEM_LOOKUP:
							return false
						return (ITEM_LOOKUP[shopItemName] == args.colorFlags) != args.invert
				FilterTypes.PERK:
					return true
	return true

##The method that filters cards
func card_filter(inCard : CardData, args : Dictionary) -> bool:
	#And
	if args.exact:
		return inCard.colors & args.colorFlags == args.colorFlags
	#Or
	return (inCard.colors & args.colorFlags) > 0

##The method that filters pips
func pip_filter(inPip : MapPip, args : Dictionary) -> bool:
	return args.colorFlags == int(pow(2, inPip.colorIndex))

##Builds the text of the filter
func construct_filter_text(_input, args : Dictionary) -> String:
	var prefix : String = ""
	if args.invert:
		prefix = "not "
	var colorEntries : Array[String] = []
	if args.colorFlags == 0b000000:
		return prefix + " colorless"
	if args.colorFlags & 0b000001:
		colorEntries.append("red")
	if args.colorFlags & 0b000010:
		colorEntries.append("green")
	if args.colorFlags & 0b000100:
		colorEntries.append("violet")
	if args.colorFlags & 0b001000:
		colorEntries.append("orange")
	if args.colorFlags & 0b010000:
		colorEntries.append("blue")
	if args.colorFlags & 0b100000:
		colorEntries.append("yellow")
	var lastEntry = colorEntries.pop_back()
	if colorEntries.size() == 0:
		return prefix + " " + lastEntry
	var output = ", ".join(colorEntries)
	var collectionType : String = " or "
	if args.exact:
		collectionType = " and "
	output += collectionType + lastEntry
	return output
