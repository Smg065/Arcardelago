extends Resource
##The root of all card tag effects
class_name CardTagBase
##The colors this tag belongs to
@export_flags("Red", "Green", "Violet", "Orange", "Blue", "Yellow") var colors : int = 0

##How much this particular tag costs.
##Cards Spawn with the Following:[br]
## 6 Points - Filler Items[br]
##12 Points - Useful Items[br]
##18 Points - Progresison Items[br]
##24 Points - Proguseful Items & Traps
@export var cost : int = 1

##Strings that represent what this effect does.
@export var tags : PackedStringArray
##Prevent abilities with these tags from being paired together
@export var tagBlacklist : PackedStringArray
##Only allow abilities with these tags to be paired together
@export var tagWhitelist : PackedStringArray

##Checks if the tag blacklist or whitelist would conflict with existing tags
func compatable(previousTags : Array[CardTagBase], metaTags : PackedStringArray = PackedStringArray()):
	var allPreviousTags := PackedStringArray()
	allPreviousTags.append_array(metaTags)
	#Backsearch for tag conflicts with the tags this entry has
	if previousTags.size() > 1:
		for previousTag in previousTags:
			if !previousTag.compatable([self], metaTags):
				return false
			#Gather previous tags while we're here
			allPreviousTags.append_array(previousTag.tags)
	#For each unique tag
	var seenTags := PackedStringArray()
	for eachTag in allPreviousTags:
		if eachTag in seenTags:
			continue
		seenTags.append(eachTag)
		#Kickback on blacklist inclusion
		if eachTag in tagBlacklist:
			return false
		#Whitelists only matter if there's more than 1 whitelisted tag
		if tagWhitelist.size() > 0:
			if not eachTag in tagWhitelist:
				return false
	#If nothing fails, it passes
	return true
