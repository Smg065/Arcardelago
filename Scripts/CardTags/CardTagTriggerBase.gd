extends CardTagBase
##Base class for card tags that trigger other tags
class_name CardTagTriggerBase

##The name of the trigger type
@export var eventName : String
#A list of filters to apply to the given
@export var filters : Array[CardTagFilterBase]
#A signal that emits when this tag is triggered
signal triggered

func connect_signal():
	CSM.signalLookup[eventName].update.connect(filter_pass)

func filter_pass(...args):
	if filters.size() == 0:
		return
	match CSM.signalLookup[eventName].info.signalType:
		EffectSignalInfo.SignalType.INSTANT:
			for index in filters.size():
				if !filters[index].filter_passes(args[index]):
					return
			triggered.emit(args)
		EffectSignalInfo.SignalType.OCCURANCES:
			for index in filters.size():
				var validArgs := []
				for eachOccurance in args[index]:
					if filters[index].filter_passes(eachOccurance):
						return
				args[index] = validArgs
			triggered.emit(args)
		EffectSignalInfo.SignalType.COUNTER:
			triggered.emit(args[0])
