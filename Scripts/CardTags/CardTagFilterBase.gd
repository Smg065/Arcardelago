extends CardTagBase
##The base that makes all filters work.
class_name CardTagFilterBase

enum FilterTypes {CARD, NUMERIC, NODE, ITEMS, EVENTS, INSTANTS, INCOME_SOURCE, PURCHASABLES, PERK}
enum ArgumentTypes {STRING, INT, BOOL}

##The name of the filter type to use
@export var filterName : String
##The catagory this filter uses
@export var filterTypes : Array[FilterTypes]
##The expected arguments as a dictionary
@export var expectedArgs : Dictionary[String, ArgumentTypes]

##Validates the variable type given the filter
static func validate_type(filterType : FilterTypes, input) -> bool:
	match filterType:
		FilterTypes.CARD:
			return input is CardData
		FilterTypes.NUMERIC:
			return input is int or input is float
		FilterTypes.NODE:
			return input is MapPip
		FilterTypes.ITEMS | FilterTypes.EVENTS | FilterTypes.INSTANTS:
			if input in ItemHandler.ITEM_NAME_TABLE:
				match ItemHandler.ITEM_NAME_TABLE[input]:
					ItemHandler.ItemClasses.INVENTORY:
						return filterType == FilterTypes.ITEMS
					ItemHandler.ItemClasses.EVENT:
						return filterType == FilterTypes.EVENTS
					ItemHandler.ItemClasses.INSTANT:
						return filterType == FilterTypes.INSTANTS
			return false
		FilterTypes.INCOME_SOURCE:
			if input is Dictionary:
				return "Earned" in input
			return false
		FilterTypes.PURCHASABLES:
			if input is Dictionary:
				return "Spent" in input
			return false
		FilterTypes.PERK:
			return true
	return false

##Builds the text of the filter
@warning_ignore("unused_parameter")
func construct_filter_text(input, args : Dictionary) -> String:
	return ""

##Checks if the given type passes
func filter_passes(_input, args : Dictionary) -> bool:
	for eachExpected in expectedArgs:
		if !eachExpected in args:
			push_error("Incorrect argument!")
			return false
		match expectedArgs[eachExpected]:
			ArgumentTypes.STRING:
				if !args[eachExpected] is String:
					push_error("Expected %s to be a string!" % eachExpected)
					return false
			ArgumentTypes.INT:
				if !args[eachExpected] is int:
					push_error("Expected %s to be a integer!" % eachExpected)
					return false
			ArgumentTypes.BOOL:
				if !args[eachExpected] is bool:
					push_error("Expected %s to be a bool!" % eachExpected)
					return false
	return true
