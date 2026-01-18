extends CardTagBase
##Base class for card tags that cause effects
class_name CardTagEffectBase

##The name of the effect
@export var effectName : String
##The effect text that will show up on the card.
@export_multiline var cardText : String


##The kind of signal script this will use
@export var signalFilters : Array[FilterTypes]
##The types of data expected to be passed in
enum FilterTypes {CARD, NUMERIC, NODE, ITEMS, EVENTS, INSTANTS, INCOME_SOURCE, PURCHASABLES, PERK}

##The trigger types this is compatable with
@export var compatableTriggers : Array[EffectSignalInfo.SignalType]

##Gets the prefix for when this starts the card
func get_text(textInjects : Array[String] = []):
	return (cardText % textInjects).trim_prefix(" ")
