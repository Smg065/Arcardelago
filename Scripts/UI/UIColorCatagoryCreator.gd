extends TextureRect
class_name ColorCatagoryCreatorUI

@export var wordWeightPrefab : PackedScene

@export var nameInput : LineEdit
const CUSTOM = ColorCatagory.ColorTypes.CUSTOM
@export var colorInput : ColorPickerButton
@export var descriptionInput : TextEdit

@export var lookupTagsColorHolder : VBoxContainer
@export var lookupTagsColorInput : Array[WordWeightEntry]
@export var lookupTagsPartsInput : Array[PartOfSpeechEntryUI]

@export var phonNameInput : MenuButton
@export var phonTypesInput : MenuButton
@export var phonDiacriticCommandInput : MenuButton
@export var phonVowelGoalToggle : CheckBox
@export var phonVowelGoalXInput : HSlider
@export var phonVowelGoalYInput : VSlider
@export var phonVowelGoalPosition : Control
@export var phonVowelGoalLabel : Label
@export var phonVowelRoundPrefInput : MenuButton
@export var phonConsonantSoundInput : MenuButton
@export var phonConsonantShapeInput : MenuButton
@export var phonConsonantVoicedInput : MenuButton

@export var phonToneGoalToggle : CheckBox
@export var phonToneGoalLabel : Label
@export var phonToneGoalInput : HSlider

@export var itemQualityMultiInput = SpinBox
@export_flags("Progression", "Useful", "Trap") var itemQualityFlags : PackedInt32Array
@export var itemSourcePrefInput : OptionButton

func _ready() -> void:
	for eachPhon in Phonetics.LOOKUP:
		phonNameInput.get_popup().add_check_item(eachPhon.name)

func tone_toggled(toggled_on: bool) -> void:
	phonToneGoalInput.editable = toggled_on

func tone_value_changed(value: float) -> void:
	phonToneGoalLabel.text = "%1.2f" % value


func vowel_goal_toggled(toggled_on: bool) -> void:
	phonVowelGoalXInput.editable = toggled_on
	phonVowelGoalYInput.editable = toggled_on
	phonVowelGoalPosition.visible = toggled_on

func vowel_x_changed(value: float) -> void:
	set_cursor_pos(Vector2(value, phonVowelGoalYInput.value))

func vowel_y_changed(value: float) -> void:
	set_cursor_pos(Vector2(phonVowelGoalXInput.value, value))

func set_cursor_pos(newPos : Vector2):
	var cursorPos := (newPos + Vector2.ONE) / 2.0
	cursorPos.y = 1 - cursorPos.y
	phonVowelGoalPosition.anchor_left = cursorPos.x
	phonVowelGoalPosition.anchor_right = cursorPos.x
	phonVowelGoalPosition.anchor_bottom = cursorPos.y
	phonVowelGoalPosition.anchor_top = cursorPos.y
	phonVowelGoalLabel.text = "%1.2f, %1.2f" % [newPos.x, newPos.y]

func add_pressed() -> WordWeightEntry:
	var wwe : WordWeightEntry = wordWeightPrefab.instantiate()
	lookupTagsColorHolder.add_child(wwe)
	lookupTagsColorInput.append(wwe)
	wwe.set_shifts(shift_entry)
	wwe.erase_started.connect(remove_entry.bind(wwe))
	order_entries()
	return wwe

func remove_entries():
	for eachInput in lookupTagsColorInput:
		eachInput.queue_free()
	lookupTagsColorInput.clear()

func remove_entry(wwe : WordWeightEntry):
	lookupTagsColorInput.erase(wwe)
	wwe.queue_free()
	order_entries()

func order_entries():
	for eachChild in lookupTagsColorInput:
		var newIndex : int = lookupTagsColorInput.find(eachChild)
		lookupTagsColorHolder.move_child(eachChild, newIndex)
		eachChild.set_shifts_enabled(newIndex > 0, newIndex < lookupTagsColorInput.size() - 1)

func shift_entry(targetUi : WordWeightEntry, moveDir : int):
	var entryIndex : int = lookupTagsColorInput.find(targetUi)
	lookupTagsColorInput.remove_at(entryIndex)
	lookupTagsColorInput.insert(entryIndex + moveDir, targetUi)
	order_entries()
