extends Resource
class_name HomeStructure

##The name of the room
@export var name : String
##What house upgrade unlocks this room
@export var unlocks : int
##What it looks like when the room's missing
@export var missingArea : Texture2D
##What it looks like when the room's built
@export var builtArea : Texture2D
