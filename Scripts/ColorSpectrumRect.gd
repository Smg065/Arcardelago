extends TextureRect
class_name ColorSpectrumRect

const CENTER = Vector2(0.5, 0.5)
@export_flags("Red", "Green", "Violet", "Orange", "Blue", "Yellow") var colors : int = 0

const RED = ColorCatagory.ColorTypes.RED
const GREEN = ColorCatagory.ColorTypes.GREEN
const VIOLET = ColorCatagory.ColorTypes.VIOLET
const ORANGE = ColorCatagory.ColorTypes.ORANGE
const BLUE = ColorCatagory.ColorTypes.BLUE
const YELLOW = ColorCatagory.ColorTypes.YELLOW

func build(dirAngle : float) -> void:
	var gradTex : GradientTexture2D = texture
	while gradTex.gradient.get_point_count() > 1:
		gradTex.gradient.remove_point(1)
	var colorSpectrum := PackedColorArray()
	#Set the color flags
	if colors & 0b000001:
		colorSpectrum.append(ColorCatagory.get_color(RED))
	if colors & 0b000010:
		colorSpectrum.append(ColorCatagory.get_color(GREEN))
	if colors & 0b000100:
		colorSpectrum.append(ColorCatagory.get_color(VIOLET))
	if colors & 0b001000:
		colorSpectrum.append(ColorCatagory.get_color(ORANGE))
	if colors & 0b010000:
		colorSpectrum.append(ColorCatagory.get_color(BLUE))
	if colors & 0b100000:
		colorSpectrum.append(ColorCatagory.get_color(YELLOW))
	#If there's none, default to being transparent
	if colorSpectrum.size() == 0:
		colorSpectrum.append(Color.TRANSPARENT)
	
	#Set the first color
	gradTex.gradient.set_color(0, colorSpectrum[0])
	#Constant cutoffs need an extra buffer spot
	var offsetMulti : float = 1
	if gradTex.gradient.interpolation_mode == Gradient.InterpolationMode.GRADIENT_INTERPOLATE_CONSTANT:
		offsetMulti = 1 - (1.0 / colorSpectrum.size())
	#If there's only 1 color, leave it at that
	for colorIndex in range(1, colorSpectrum.size()):
		var setPoint : float = float(colorIndex) / (colorSpectrum.size() - 1) * offsetMulti
		gradTex.gradient.add_point(setPoint, colorSpectrum[colorIndex])
	var rndGradAngle = Vector2.from_angle(dirAngle) / 2.0
	gradTex.fill_from = CENTER + rndGradAngle
	gradTex.fill_to = CENTER - rndGradAngle

func default():
	var gradTex : GradientTexture2D = texture
	while gradTex.gradient.get_point_count() > 1:
		gradTex.gradient.remove_point(1)
	gradTex.gradient.set_color(0, Color.BLACK)
