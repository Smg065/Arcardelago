extends Resource
class_name CardAbilityBundle

##Names the triggers
var triggers : PackedStringArray
##Names of the effect
var effects : PackedStringArray
##Filter entries
var filters : Array[Dictionary]

##Save data for the card ability
func json_save() -> Dictionary:
	return {
		"triggers" = triggers,
		"effects" = effects,
		"filters" = filters
	}

##Load the card ability from a dictionary
static func json_load(inData : Dictionary) -> CardAbilityBundle:
	var ncab := CardAbilityBundle.new()
	ncab.triggers = inData.triggers
	ncab.effects = inData.effects
	for eachFilter in inData.filters:
		ncab.filters.append(eachFilter)
	return ncab

##Return all tags that would be on this
func get_tags() -> Array[CardTagBase]:
	var output : Array[CardTagBase] = []
	for eachTrigger in triggers:
		output.append(CSM.signalLookup[eachTrigger].info)
	for eachEffect in effects:
		output.append(CSM.effectLookup[eachEffect])
	for eachFilter in filters:
		output.append(CSM.filterLookup[eachFilter.name])
	return output

##Setup all triggers to filter passes
func setup_signals():
	#All signal types must match
	var filterCallable : Callable
	match CSM.signalLookup[triggers[0]].info.signalType:
		EffectSignalInfo.SignalType.INSTANT:
			filterCallable = instant_filter
		EffectSignalInfo.SignalType.COUNTER:
			filterCallable = counter_filter
		EffectSignalInfo.SignalType.OCCURANCES:
			filterCallable = occurance_filter
	#Get all the triggers and the filters they will use
	var triggerLookup : Dictionary = {}
	for triggerIndex in triggers.size():
		var requiredFilters := construct_filter_function_array(triggerIndex, "triggers")
		var cardSignal := CSM.signalLookup[triggers[triggerIndex]]
		triggerLookup[cardSignal] = requiredFilters
	#Apply each trigger to all effects
	for effectIndex in effects.size():
		var requiredFilters := construct_filter_function_array(effectIndex, "effects")
		for eachSignal in triggerLookup:
			eachSignal = eachSignal as ESB
			eachSignal.update.connect(filterCallable.bind(triggerLookup[eachSignal], requiredFilters, effectIndex))

##Instant filters
func instant_filter(...args):
	for eachArg in args:
		print(eachArg)

##Counter filters
func counter_filter(...args):
	for eachArg in args:
		print(eachArg)

##Occurance filters
func occurance_filter(...args):
	for eachArg in args:
		print(eachArg)

##Filter functions callback
func construct_filter_function_array(entryIndex : int, appliedType : String) -> Array[Callable]:
	var output : Array[Callable]
	for eachFilter in filters:
		if appliedType in eachFilter:
			if entryIndex in eachFilter[appliedType]:
				output.append(CSM.filterLookup[eachFilter.name].filter_passes.bind(eachFilter.args))
	return output

##Return the filter constructor
func create_trigger(signalName : String):
	var signalInfo := CSM.signalLookup[signalName].info
	for eachType in signalInfo.signalFilters:
		var validFilters : PackedStringArray
		for eachFilter in CSM.filterLookup:
			if eachType in CSM.filterLookup[eachFilter].filterTypes:
				validFilters.append(eachFilter)

##Display what this card does
func construct_text() -> String:
	var triggersOutput : Array[String] = []
	var effectsOutput : Array[String] = []
	for triggerIndex in triggers.size():
		var eachTrigger := CSM.signalLookup[triggers[triggerIndex]].info
		var passStrings : Array[String] = []
		for filterSlots in eachTrigger.signalFilters.size():
			var filterText := ""
			for eachFilter in filters:
				if float(triggerIndex) in eachFilter.Triggers:
					filterText = ColorCatagory.COLOR_NAMES.pick_random().to_lower()
			passStrings.append(filterText)
		triggersOutput.append(eachTrigger.get_text(triggerIndex == 0, passStrings))
	for effectIndex in effects.size():
		var eachEffect := CSM.effectLookup[effects[effectIndex]]
		var passStrings : Array[String] = []
		for filterSlots in eachEffect.signalFilters.size():
			var filterText := ""
			for eachFilter in filters:
				if float(effectIndex) in eachFilter.Effects:
					filterText = ColorCatagory.COLOR_NAMES.pick_random().to_lower()
			passStrings.append(filterText)
		effectsOutput.append(eachEffect.get_text(passStrings))
	return ", ".join([" or ".join(triggersOutput), " and ".join(effectsOutput)]) + "."
