extends Resource
class_name CardAbilityBundle

var triggers : Dictionary
var effect : CardTagEffectBase

##Causes all the effects to be run
func ability_triggered():
	effect.trigger()

func create_trigger(signalName : String):
	var signalInfo := CSM.signalLookup[signalName].info
	
	for eachType in signalInfo.signalFilters:
		var validFilters : PackedStringArray
		for eachFilter in CSM.filterLookup:
			if eachType in CSM.filterLookup[eachFilter].filterTypes:
				validFilters.append(eachFilter)
		
	{
		"signalName" : "thing2"
	}
