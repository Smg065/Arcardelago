extends Node
##Signal manager for card effects
class_name CardSignalManager

##Signal directory
const SIGNAL_DIR = "res://Resources/EffectSignals/"

##Filter directory
const FILTER_DIR = "res://Resources/EffectFilters/"

##Effect directory
const EFFECTS_DIR = "res://Resources/Effects/"

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
	#Constructs all the filters
	var files := ResourceLoader.list_directory(EFFECTS_DIR)
	for filename in files:
		var filepath = EFFECTS_DIR + filename
		var effectTag : CardTagEffectBase = load(filepath)
		effectLookup[effectTag.effectName] = effectTag

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
		if collectionType != "Filters":
			output.append_array(recursive_compatability(collectionType, typeCollections[eachType], 3))
		else:
			#Make sure there's no duplicate entries for filters
			for eachFilter in recursive_compatability(collectionType, typeCollections[eachType], 3):
				if !eachFilter in output:
					output.append(eachFilter)
	return output

##Recursively steps down each combination of input lookups and checks for compatability problems
func recursive_compatability(collectionType : String, inputLookup : Array, maxSize : int, previousTags : Dictionary[String, CardTagBase] = {}) -> Array[PackedStringArray]:
	var lookupCopy := inputLookup.duplicate()
	var entryName : String = lookupCopy.pop_back()
	var eachEntry := get_entry(collectionType, entryName)
	var validCombinations : Array[PackedStringArray] = []
	#While there's recursive steps left, and recurring won't give you too many tags
	if not lookupCopy.is_empty() and previousTags.size() < maxSize - 1:
		#See all entries that exclude this
		validCombinations = recursive_compatability(collectionType, lookupCopy, maxSize, previousTags)
		#If you're allowed to include all previous attempt, include those
		if eachEntry.compatable(previousTags.values()):
			var previousTagsAndThis := previousTags.duplicate()
			previousTagsAndThis[entryName] = eachEntry
			validCombinations.append_array(recursive_compatability(collectionType, lookupCopy, maxSize, previousTagsAndThis))
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
func construct_abiity(rng : RandomNumberGenerator, points : int, colors : int, previousTags : Array[CardTagBase], metaTags : PackedStringArray) -> CardAbilityBundle:
	##All subsets that contain potential effects this can use
	var psTriggers := potential_subsets("Triggers", colors, previousTags, metaTags)
	##All subsets that contain potential fitlers this can use
	var psFilters := potential_subsets("Filters", colors, previousTags, metaTags)
	##All subsets that contain potential effects this can use
	var psEffects := potential_subsets("Effects", colors, previousTags, metaTags)
	
	##A dictionary containing valid entries and goals
	var bestSolutions : Array = []
	
	#The distance from the target points
	var bestPointDistance : int = 99
	
	#Create all valid card configurations
	for esT in psTriggers:
		#Get the costs
		var triggersCost := 0
		#Append the 'Previous Tags' list
		for triggerNames in esT:
			triggersCost += esT[triggerNames].cost
		var triggerTags : Array[CardTagBase] = esT.values()
		#Effects Layer
		for esE in psEffects:
			var effectsCost := 0
			var effectsCompatable : bool = true
			for effectNames in esE:
				effectsCost += esE[effectNames].cost
				if not esE[effectNames].compatable(triggerTags, metaTags):
					effectsCompatable = false
					break
			var effectTags : Array[CardTagBase] = esE.values()
			#If any of the tags are incompatable
			if !effectsCompatable:
				continue
			
			#Trigger filters
			var baseTags : Array[CardTagBase]
			baseTags.append_array(triggerTags)
			baseTags.append_array(effectTags)
			
			#Check if the base combo meets or beats the current distance score
			var basePointCost : int = triggersCost + effectsCost
			var basePointDistance : int = abs(points - basePointCost)
			#If it beats it, set the new standard
			if basePointDistance < bestPointDistance:
				bestPointDistance = basePointDistance
				bestSolutions.clear()
			#If it meets it, append it to the point lookup
			if basePointDistance == bestPointDistance:
				var baseSolution := {}
				for eachTag in baseTags:
					baseSolution[eachTag] = []
					for eachFilter in eachTag.signalFilters:
						baseSolution[eachTag].append(null)
				bestSolutions.append(baseSolution)
			
			#No filters needed on perfect matches, or tag combinations need more points
			if basePointCost <= points:
				continue
			var results := recursive_tag_combos(baseTags, psFilters)
			for eachKey in results:
				var filterPointDistance = abs(points - eachKey)
				if filterPointDistance < bestPointDistance:
					bestPointDistance = filterPointDistance
					bestSolutions.clear()
				if filterPointDistance == bestPointDistance:
					bestSolutions.append_array(results[eachKey])
	
	#Make it more likely to select simpler cards
	var weights := PackedFloat32Array()
	for eachSolution in bestSolutions:
		var totalCount = 0
		for eachTag in eachSolution:
			totalCount += 1
			totalCount += eachSolution[eachTag].size() - eachSolution[eachTag].count(null)
		weights.append(1 / float(totalCount))
	#If there's nothing to choose, return null to show there's no valid abilities left
	if weights.is_empty():
		return null
	#Choose one
	var chosenSolution = bestSolutions[rng.rand_weighted(weights)]
	#Translate it
	var newAbility := CardAbilityBundle.new()
	for eachTag in chosenSolution:
		if eachTag is EffectSignalInfo:
			newAbility.triggers.append(eachTag.name)
		if eachTag is CardTagEffectBase:
			newAbility.effects.append(eachTag.effectName)
	for eachTag in chosenSolution:
		for eachFilterBundle in chosenSolution[eachTag]:
			if eachFilterBundle == null:
				continue
			for eachFilter in eachFilterBundle:
				var hasFilter : bool = false
				var targetIndex : int = -1
				for filterIndex in newAbility.filters.size():
					if newAbility.filters[filterIndex].name == eachFilter:
						hasFilter = true
						targetIndex = filterIndex
						break
				if !hasFilter:
					newAbility.filters.append({"name" : eachFilter})
				if eachTag is EffectSignalInfo:
					newAbility.filters[targetIndex] = PD.append_dict_entry(newAbility.filters[targetIndex], "Triggers", newAbility.triggers.find(eachTag.name))
				if eachTag is CardTagEffectBase:
					newAbility.filters[targetIndex] = PD.append_dict_entry(newAbility.filters[targetIndex], "Effects", newAbility.effects.find(eachTag.effectName))
	return newAbility

##Return all filter permutations
func recursive_tag_combos(allTags : Array[CardTagBase], psFilters, tagAttempts : Dictionary = {}, currentCost : int = 0) -> Dictionary:
	var output : Dictionary = {}
	#Tag plugins
	for eachTag in allTags:
		if not eachTag in tagAttempts:
			tagAttempts[eachTag] = []
		var attemptsIndex = tagAttempts[eachTag].size()
		if attemptsIndex >= eachTag.signalFilters.size():
			continue
		#All filtered version of this tag
		for esF in psFilters:
			if not eachTag.signalFilters[attemptsIndex] in esF.values()[0].filterTypes:
				continue
			var newTagAttempt := tagAttempts.duplicate()
			newTagAttempt[eachTag].append(esF)
			var divisorSize : float = 1
			for eachFilter in esF:
				divisorSize *= esF[eachFilter].divisor
			var newCost : int = currentCost + ceili(eachTag.cost / divisorSize)
			var upstream := recursive_tag_combos(allTags, psFilters, newTagAttempt, newCost)
			for eachKey in upstream:
				if not eachKey in output:
					output[eachKey] = []
				for eachEntry in upstream[eachKey]:
					if not eachEntry in output[eachKey]:
						output[eachKey].append(eachEntry)
		#All unfiltered versions of this tag
		var filterlessAttempt := tagAttempts.duplicate()
		filterlessAttempt[eachTag].append(null)
		var noFilterUpstream := recursive_tag_combos(allTags, psFilters, filterlessAttempt, currentCost + eachTag.cost)
		for eachKey in noFilterUpstream:
			if not eachKey in output:
				output[eachKey] = []
			for eachEntry in noFilterUpstream[eachKey]:
				if not eachEntry in output[eachKey]:
					output[eachKey].append(eachEntry)
		return output
	return {currentCost : [tagAttempts.duplicate()]}

##Get all subets that only consist of potential entries
func potential_subsets(subsetType : String, colors : int, previousTags : Array[CardTagBase], metaTags : PackedStringArray) -> Array:
	var output : Array = []
	var potentialEntries : Dictionary[String, CardTagBase] = get_compatable_entries(subsetType, colors, previousTags, metaTags)
	for eachSubset in _tagSubsets[subsetType]:
		var validSubset : bool = true
		var potentialOutput : Dictionary[String, CardTagBase] = {}
		for eachEntry in eachSubset:
			if not eachEntry in potentialEntries:
				validSubset = false
				break
			potentialOutput[eachEntry] = potentialEntries[eachEntry]
		if validSubset:
			output.append(potentialOutput)
	return output

##Get all entries that are self-compatable in this collection
func get_compatable_entries(subsetType : String, colors : int, previousTags : Array[CardTagBase], metaTags : PackedStringArray) -> Dictionary[String, CardTagBase]:
	var validEntries : Dictionary[String, CardTagBase] = {}
	var toLookup : Dictionary
	match subsetType:
		"Triggers":
			toLookup = signalLookup
		"Effects":
			toLookup = effectLookup
		"Filters":
			toLookup = filterLookup
	for eachEntry in toLookup:
		var entryData := get_entry(subsetType, eachEntry)
		if (entryData.colors | colors) and entryData.colors != colors:
			continue
		if entryData.compatable(previousTags, metaTags):
			validEntries[eachEntry] = entryData
	return validEntries
