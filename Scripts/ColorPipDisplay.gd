extends AspectRatioContainer
class_name ColorPipDisplay
@export var pipImage : Texture2D
@export_flags("Red", "Green", "Violet", "Orange", "Blue", "Yellow") var colors : int = 0

const RED = ColorCatagory.ColorTypes.RED
const GREEN = ColorCatagory.ColorTypes.GREEN
const VIOLET = ColorCatagory.ColorTypes.VIOLET
const ORANGE = ColorCatagory.ColorTypes.ORANGE
const BLUE = ColorCatagory.ColorTypes.BLUE
const YELLOW = ColorCatagory.ColorTypes.YELLOW

func build() -> void:
	var container : Control = get_child(0)
	var toBuild : Array[ColorCatagory.ColorTypes]
	if colors & 0b000001:
		toBuild.append(RED)
	if colors & 0b000010:
		toBuild.append(GREEN)
	if colors & 0b000100:
		toBuild.append(VIOLET)
	if colors & 0b001000:
		toBuild.append(ORANGE)
	if colors & 0b010000:
		toBuild.append(BLUE)
	if colors & 0b100000:
		toBuild.append(YELLOW)
	#Colorless
	if toBuild.size() == 0:
		var textureRect := TextureRect.new()
		textureRect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		textureRect.texture = pipImage
		textureRect.tooltip_text = "Colorless"
		container.add_child(textureRect)
		textureRect.set_anchors_preset(Control.PRESET_FULL_RECT)
	else:
		for colorIndex in toBuild.size():
			var eachColor := toBuild[colorIndex]
			var textureBar := TextureProgressBar.new()
			textureBar.nine_patch_stretch = true
			textureBar.texture_progress = pipImage
			textureBar.tint_progress = ColorCatagory.get_color(eachColor)
			textureBar.step = 0
			textureBar.value = 100.0 / toBuild.size()
			textureBar.radial_initial_angle = colorIndex * 360.0 / toBuild.size()
			textureBar.radial_initial_angle -= 180.0 / toBuild.size()
			textureBar.fill_mode = TextureProgressBar.FillMode.FILL_CLOCKWISE
			textureBar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			container.add_child(textureBar)
			textureBar.set_anchors_preset(Control.PRESET_FULL_RECT)
