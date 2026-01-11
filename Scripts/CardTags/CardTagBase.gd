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
@export var cost : int

##Strings that represent what this effect does.
@export var tags : PackedStringArray
##Prevent abilities with these tags from being paired together
@export var tagBlacklist : PackedStringArray
##Only allow abilities with these tags to be paired together
@export var tagWhitelist : PackedStringArray
