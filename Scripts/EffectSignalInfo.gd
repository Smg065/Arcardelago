extends Resource
class_name EffectSignalInfo

##The name of the signal
@export var name : String

##The name of the signal
@export_multiline var cardText : String

##The kind of signal script this will use
@export var signalType : SignalType

##The kind of signal script this will use
@export var signalFilters : Array[FilterTypes]

##The kind of signal script this will use
@export_range(0, 30) var effectCost : int = 1

##The kinds of signals that exist for effects
enum SignalType {INSTANT, OCCURANCES, COUNTER}

##The types of data expected to be passed in
enum FilterTypes {CARD, NUMERIC, NODE, ITEMS, EVENTS, INSTANTS, INCOME_SOURCE, PURCHASABLES, PERK}

##Gets the prefix for when this starts the card
func get_text(prefixed : bool = false, textInjects : PackedStringArray = PackedStringArray()):
	var prefix = ""
	if prefixed:
		match signalType:
			SignalType.INSTANT:
				prefix = "When "
			SignalType.OCCURANCES:
				prefix = "For each "
			SignalType.COUNTER:
				prefix = "For each "
	if textInjects.size() == 0:
		return prefix + cardText.replace("%s", "").trim_prefix(" ")
	return prefix + (cardText % textInjects).trim_prefix(" ")
