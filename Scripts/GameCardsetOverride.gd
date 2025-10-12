extends Resource
class_name GameCardsetOverride

@export var gameName : String
@export_flags("Red", "Green", "Violet", "Orange", "Blue", "Yellow") var colors : int = 0
@export var cardOverrideTable : Array[CardDataOverride]
