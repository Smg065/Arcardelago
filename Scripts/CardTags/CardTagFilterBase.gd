extends CardTagBase
##The base that makes all filters work.
class_name CardTagFilterBase

enum FilterTypes {CARD, NUMERIC, NODE, ITEMS, EVENTS, INSTANTS, INCOME_SOURCE, PURCHASABLES, PERK, BUNDLE}

##The name of the filter type to use
@export var filterName : String
##
@export var filterTypes : FilterTypes

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
			return input is String
		FilterTypes.PURCHASABLES:
			return input is Dictionary
		FilterTypes.PERK:
			return true
	return false

##Builds the text of the filter
@warning_ignore("unused_parameter")
func construct_filter_text(...args) -> String:
	return ""

##Checks if the given type passes
@warning_ignore("unused_parameter")
func filter_passes(input) -> bool:
	return true
