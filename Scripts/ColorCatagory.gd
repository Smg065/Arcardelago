extends Resource
class_name ColorCatagory

enum ColorTypes {RED, GREEN, VIOLET, ORANGE, BLUE, YELLOW}
const RED = ColorTypes.RED
const GREEN = ColorTypes.GREEN
const VIOLET = ColorTypes.VIOLET
const ORANGE = ColorTypes.ORANGE
const BLUE = ColorTypes.BLUE
const YELLOW = ColorTypes.YELLOW
enum SourcePref {NULL, LOCAL, EXTERNAL}
@export var colorType : ColorTypes
@export_color_no_alpha var color : Color
@export_multiline var description : String

@export_group("Word Tags", "lookupTags")
@export var lookupTagsColor : Array[WordWeight]
@export var lookupTagsNames : Array[WordWeight]
@export var lookupTagsPhonetic : Array[WordWeight]
@export_group("AP Data", "item")
@export_flags("Progression", "Useful", "Trap") var itemQualityFlags : PackedInt32Array
@export var itemSourcePref : SourcePref

static func get_color(inColorType : ColorTypes) -> Color:
	match inColorType:
		RED:
			return Color.hex(0xC3727EFF)
		GREEN:
			return Color.hex(0x76C173FF)
		VIOLET:
			return Color.hex(0xC894C4FF)
		ORANGE:
			return Color.hex(0xD8A07FFF)
		BLUE:
			return Color.hex(0x767EBDFF)
		YELLOW:
			return Color.hex(0xEEE391FF)
		_:
			return Color.BLACK
