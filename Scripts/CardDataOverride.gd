extends Resource
class_name CardDataOverride

@export var cardName : String
enum CardType {DEFAULT, FILLER, USEFUL, PROGRESSION, PROGUSEFUL, TRAP, LOCATION}
@export var cardType : CardType

@export_category("Info Overrides")
@export var wordsOverrides : PackedStringArray
@export var partOfSpeechOverrides : PackedStringArray
@export var phoneticOverrides : PackedStringArray

@export_category("Stat Overrides")
@export_flags("Red", "Green", "Violet", "Orange", "Blue", "Yellow") var colors : int = 0
@export_range(1, 10) var baseHealth : int = 1
@export_range(1, 10) var basePower : int = 1
