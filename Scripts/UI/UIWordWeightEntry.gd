extends SubEntry
class_name WordWeightEntry


func weight_changed(value: float) -> void:
	$SliderControl/WeightDisplay.text = "%1.2f" % value
