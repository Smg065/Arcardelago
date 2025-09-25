extends HBoxContainer
class_name SubEntry

signal erase_started

func set_shifts(shiftCallable : Callable):
	$NudgeControl/NudgeUp.pressed.connect(shiftCallable.bind(self, -1))
	$NudgeControl/NudgeDown.pressed.connect(shiftCallable.bind(self, 1))

func set_shifts_enabled(upEnabled : bool, downEnabled : bool):
	$NudgeControl/NudgeUp.disabled = !upEnabled
	$NudgeControl/NudgeDown.disabled = !downEnabled

func delete_pressed():
	erase_started.emit()
