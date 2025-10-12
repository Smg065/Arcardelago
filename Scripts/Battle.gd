extends GameScreen
class_name Battle

##If the mouse is over the battlefield
var mouseFocused : bool
var draggingMap : bool
var mouseStartPoint : Vector2
var mapStartPoint : Vector2

##The map where the battle is happening
@export var battlemap : AspectRatioContainer
@export var battleScroll : ScrollContainer

##The zoom of the map. Range from 0-20
var zoomVal : int

func set_active(nState : bool):
	visible = nState

func _input(event: InputEvent) -> void:
	if !mouseFocused and !draggingMap:
		return
	if event is InputEventMouse:
		battlemap.pivot_offset = event.global_position - battlemap.global_position
	if event is InputEventMouseButton:
		if event.is_pressed() and !event.shift_pressed:
			match event.button_index:
				MouseButton.MOUSE_BUTTON_WHEEL_UP:
					change_zoom(1)
					get_viewport().set_input_as_handled()
				MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
					change_zoom(-1)
					get_viewport().set_input_as_handled()
				MouseButton.MOUSE_BUTTON_LEFT:
					draggingMap = true
		if event.is_released():
			match event.button_index:
				MouseButton.MOUSE_BUTTON_LEFT:
					draggingMap = false
	if event is InputEventMouseMotion:
		if draggingMap:
			battlemap.global_position += event.relative

func change_zoom(zoomDir : int):
	zoomVal = clampi(zoomVal + zoomDir, 0, 25)
	var screenSize := get_viewport().get_visible_rect().size
	var smallerAxis : float = min(screenSize.x, screenSize.y)
	var minZoom := floori(sqrt(smallerAxis))
	battlemap.custom_minimum_size = Vector2.ONE * pow(minZoom + zoomVal, 2)
	battlemap.size = battlemap.custom_minimum_size

func mouse_on_battlefield() -> void:
	mouseFocused = true

func mouse_off_battlefield() -> void:
	mouseFocused = false
