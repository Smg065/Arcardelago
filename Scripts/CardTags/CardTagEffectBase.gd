extends CardTagBase
##Base class for card tags that cause effects
class_name CardTagEffectBase

##The name of the effect
@export var effectName : String

##The kind of signal script this will use
@export var signalFilters : Array[FilterTypes]
##The types of data expected to be passed in
enum FilterTypes {CARD, NUMERIC, NODE, ITEMS, EVENTS, INSTANTS, INCOME_SOURCE, PURCHASABLES, PERK}
