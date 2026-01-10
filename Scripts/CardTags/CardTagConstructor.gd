extends Resource
class_name CardTagConstructor

##All triggers
@export var allTriggers : Dictionary[String, CardTagTriggerBase]

##All filters
@export var allFilters : Dictionary[String, CardTagFilterBase]

##All effects
@export var allEffects : Dictionary[String, CardTagEffectBase]

func get_triggers():
	#CSM Triggers
	for signalName in CSM.signalLookup:
		var eachSignal := CardTagTriggerBase.new()
		eachSignal.eventName = signalName
