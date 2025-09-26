extends SubEntry
class_name WordWeightEntry


func weight_changed(value: float) -> void:
	$SliderControl/WeightDisplay.text = "%1.2f" % value

func to_word_weight() -> WordWeight:
	var ww := WordWeight.new()
	ww.word = $WordEntry.text
	ww.weight = $SliderControl/WeightSlider.value
	return ww

func from_word_weight(ww : WordWeight):
	$WordEntry.text = ww.word
	$SliderControl/WeightSlider.value = ww.weight
	weight_changed(ww.weight)
