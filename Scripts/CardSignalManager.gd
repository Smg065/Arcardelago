extends Node
##Signal manager for card effects
class_name CardSignalManager

##Signal directory
const SIGNAL_DIR = "res://Resources/EffectSignals/"

##The dictionary containing all Effect Signals
var signalLookup : Dictionary[String, ESB]

func _init() -> void:
	#Constructs all the signals
	var files := ResourceLoader.list_directory(SIGNAL_DIR)
	for filename in files:
		var filepath = SIGNAL_DIR + filename
		var signalInfo : EffectSignalInfo = load(filepath)
		var signalBase : ESB = null
		match signalInfo.signalType:
			EffectSignalInfo.SignalType.INSTANT:
				signalBase = ESB.new()
			EffectSignalInfo.SignalType.COUNTER:
				signalBase = ESCB.new()
			EffectSignalInfo.SignalType.OCCURANCES:
				signalBase = ESOB.new()
		signalBase.info = signalInfo
		signalLookup[signalInfo.name] = signalBase

##Attaches a callable to a signal by name
func consig(inName : String, inCallable : Callable):
	signalLookup[inName].update.connect(inCallable)

#----- INSTANTS ------

##Attaches a callable to a signal by name
func callsig(inName : String, ...args):
	signalLookup[inName].update.emit(args)

#----- COUNTERS ------

##Sets the count to a signal connection
func setcount(inName : String, toSet : int, ...args):
	signalLookup[inName].add_count(toSet, args)

##Adds to the count to a signal connection
func addcount(inName : String, toAdd : int, ...args):
	signalLookup[inName].add_count(toAdd, args)

##Removes count from the signal connection
func delcount(inName : String, toRemove : int, ...args):
	signalLookup[inName].add_count(toRemove, args)

#----- OCCURANCES ------

##Sets the occurances to this array
func setoccur(inName : String, ocurrances : Array, ...args):
	signalLookup[inName].set_occurances(ocurrances, args)

##Adds this occurance to a signal collection
func addoccur(inName : String, ocurrance, ...args):
	signalLookup[inName].add_occurance(ocurrance, args)

##Removes this occurance from a signal collection
func deloccur(inName : String, ocurrance, ...args):
	signalLookup[inName].remove_occurance(ocurrance, args)
