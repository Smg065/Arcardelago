extends Node
##Signal manager for card effects
class_name CardSignalManager

##Signal directory
const SIGNAL_DIR = "res://Resources/EffectSignals/"

##Filter directory
const FILTER_DIR = "res://Resources/EffectFilters/"

##The dictionary containing all Effect Signals
var signalLookup : Dictionary[String, ESB]

##The dictionary containing all Filter Tags
var filterLookup : Dictionary[String, CardTagFilterBase]

##The dictionary containing all Effect Tags
var effectLookup : Dictionary[String, CardTagEffectBase]

##A cheat sheet for valid tag combinations
var _tagSubsets : Dictionary

func _init() -> void:
	construct_signals()
	construct_filters()
	construct_effects()
	_tagSubsets = {
		"Triggers" : construct_valid_subsets("Triggers", signalLookup.keys()),
		"Filters" : construct_valid_subsets("Filters", filterLookup.keys()),
		"Effects" : construct_valid_subsets("Effects", effectLookup.keys())
	}

##Builds all signals to be used
func construct_signals():
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

##Builds all functions to be used
func construct_filters():
	#Constructs all the filters
	var files := ResourceLoader.list_directory(FILTER_DIR)
	for filename in files:
		var filepath = FILTER_DIR + filename
		var filterTag : CardTagFilterBase = load(filepath)
		filterLookup[filterTag.filterName] = filterTag

##Builds all effects to be used
func construct_effects():
	pass

##Valid subset construction based on catagories to speed up generation
func construct_valid_subsets(collectionType : String, inputLookup : PackedStringArray):
	#First get all subsets that match types
	var typeCollections : Dictionary
	for eachEntry in inputLookup:
		var lookupTypes : Array[int]
		match collectionType:
			"Triggers":
				lookupTypes = [get_entry(collectionType, eachEntry).signalType]
			"Filters":
				lookupTypes = get_entry(collectionType, eachEntry).filterTypes as Array[int]
			"Effects":
				lookupTypes = [get_entry(collectionType, eachEntry).cost]
		for eachType in lookupTypes:
			typeCollections = PD.append_dict_entry(typeCollections, eachType, eachEntry)
	#Then check for compatability via blacklist or whitelist tags
	var output : Array[PackedStringArray] = []
	for eachType in typeCollections:
		#For each compatable tag combination
		for eachEntry in recursive_compatability(collectionType, typeCollections[eachType]):
			#Only append unique ones
			if !eachEntry in output:
				output.append(eachEntry)
	return output

##Recursively steps down each combination of input lookups and checks for compatability problems
func recursive_compatability(collectionType : String, inputLookup : Array, previousTags : Dictionary[String, CardTagBase] = {}) -> Array[PackedStringArray]:
	var lookupCopy := inputLookup.duplicate()
	var entryName : String = lookupCopy.pop_back()
	var eachEntry := get_entry(collectionType, entryName)
	var validCombinations : Array[PackedStringArray] = []
	#While there's recursive steps left
	if not lookupCopy.is_empty():
		#See all entries that exclude this
		validCombinations = recursive_compatability(collectionType, lookupCopy, previousTags)
		#If you're allowed to include all previous attempt, include those
		if eachEntry.compatable(previousTags.values()):
			var previousTagsAndThis := previousTags.duplicate()
			previousTagsAndThis[entryName] = eachEntry
			validCombinations.append_array(recursive_compatability(collectionType, lookupCopy, previousTagsAndThis))
	#When you're at the root of this recursive branch
	else:
		var exclusiveEntry := PackedStringArray()
		exclusiveEntry.append_array(previousTags.keys())
		#Not including this is a valid entry
		if previousTags.size() > 0:
			validCombinations.append(exclusiveEntry)
		#If this entry is compatable with previous tags, it's also a valid entry
		if eachEntry.compatable(previousTags.values()):
			var inclusiveEntry = exclusiveEntry.duplicate()
			inclusiveEntry.append(entryName)
			validCombinations.append(inclusiveEntry)
	return validCombinations

##Gets the entry based on the string of the collection it's from and an entry name
func get_entry(collectionType : String, entryName : String) -> CardTagBase:
	match collectionType:
		"Triggers":
			return signalLookup[entryName].info
		"Filters":
			return filterLookup[entryName]
		"Effects":
			return effectLookup[entryName]
	return null

#----- Triggers ------

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

#----- CONSTRUCTOR ------

##Constructs an ability using the points you have to use
func construct_abiity(points : int, previousTags : Array[CardTagBase], metaTags : PackedStringArray) -> CardAbilityBundle:
	var newAbility := CardAbilityBundle.new()
	var potentialTriggers := get_compatable_entries(signalLookup, previousTags, metaTags, true)
	var potentialFilters := get_compatable_entries(filterLookup, previousTags, metaTags)
	var potentialEffects := get_compatable_entries(effectLookup, previousTags, metaTags)
	
	newAbility.triggers.append("eggs")
	newAbility.effects.append("test")
	return newAbility

func get_compatable_entries(toLookup : Dictionary, previousTags : Array[CardTagBase], metaTags : PackedStringArray, isEsb : bool = false) -> PackedStringArray:
	var validEntries := PackedStringArray()
	for eachEntry in toLookup:
		if isEsb:
			if toLookup[eachEntry].info.compatable(previousTags, metaTags):
				validEntries.append(eachEntry)
		else:
			if toLookup[eachEntry].compatable(previousTags, metaTags):
				validEntries.append(eachEntry)
	return validEntries
