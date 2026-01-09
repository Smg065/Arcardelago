extends CardTagBase
##Base class for card tags that trigger other tags
class_name CardTagTriggerBase

##The name of the trigger type
@export var eventName : String
#A list of filters to apply to the given
@export var filters : Array[EffectFilterBase]

func connect_signal():
	CSM.signalLookup[eventName].update.connect()

func filter_pass() -> bool:
	for eachFilter in filters:
		eachFilter
	return true
