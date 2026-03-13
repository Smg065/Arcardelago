extends CEGNBase
class_name GNLogicGate

var isNotGate : bool

func gate_type_selected(index: int) -> void:
	if isNotGate != (index == 4):
		isNotGate = index == 4
		set_slot_enabled_left(0, not isNotGate)
		set_slot_enabled_left(1, isNotGate)
		set_slot_enabled_left(2, not isNotGate)
		remove_connections(1)
