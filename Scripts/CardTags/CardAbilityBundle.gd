extends Resource
class_name CardAbilityBundle

var trigger : CardTagTriggerBase
var effect : CardTagEffectBase

##Causes all the effects to be run
func ability_triggered():
	effect.trigger()
