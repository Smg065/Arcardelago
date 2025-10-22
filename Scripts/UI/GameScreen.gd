extends CanvasLayer
class_name GameScreen

##Sets if this screen is active in the map viewer or not
func set_active(nState : bool, _nInfo : Dictionary):
	visible = nState
