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
@export var itemQualityFlagInputs : Array[CheckBox]
@export var itemSourcePrefInput : OptionButton

func _ready() -> void:
	for eachPhon in Phonetics.LOOKUP:
		phonNameInput.get_popup().add_check_item(eachPhon.name)
	$SavingBar/HGroupAlign/SaveEditor.show()
	$SavingBar/HGroupAlign/LoadEditor.show()
	
	#Menu Buttons
	connect_menu_button(phonNameInput)
	connect_menu_button(phonTypesInput)
	connect_menu_button(phonDiacriticCommandInput)
	connect_menu_button(phonVowelRoundPrefInput)
	connect_menu_button(phonConsonantSoundInput)
	connect_menu_button(phonConsonantShapeInput)
	connect_menu_button(phonConsonantVoicedInput)

func connect_menu_button(inMenu : MenuButton):
	inMenu.get_popup().id_pressed.connect(toggle_menu_button.bind(inMenu))

func toggle_menu_button(inId : int, inMenu : MenuButton):
	set_menu_button(inId, inMenu, !inMenu.get_popup().is_item_checked(inId))

func set_menu_button(inId : int, inMenu : MenuButton, checked : bool):
	inMenu.get_popup().set_item_checked(inId, checked)

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

func get_menu_checked(menuButton : MenuButton) -> PackedInt32Array:
	var outIndexes := PackedInt32Array([])
	var popupMenu : PopupMenu = menuButton.get_popup()
	for eachEntry in menuButton.item_count:
		if popupMenu.is_item_checked(eachEntry):
			outIndexes.append(eachEntry)
	return outIndexes

func to_color_catagory() -> ColorCatagory:
	var cc := ColorCatagory.new()
	### Basics ###
	cc.name = nameInput.text
	cc.color = colorInput.color
	cc.colorType = CUSTOM
	cc.description = descriptionInput.text
	## Lookups ###
	#Color Word Weights
	for eachColorInput in lookupTagsColorInput:
		cc.lookupTagsColor.append(eachColorInput.to_word_weight())
	#Parts of Speech
	for eachPartInput in lookupTagsPartsInput:
		var value := eachPartInput.get_value()
		if value != 0:
			cc.lookupTagsParts[eachPartInput.partName.to_lower()] = value
	### Phonetics ###
	#Names
	for eachChecked in get_menu_checked(phonNameInput):
		var nextName := phonNameInput.get_popup().get_item_text(eachChecked)
		cc.phonName.append(nextName)
	#Types
	for eachChecked in get_menu_checked(phonTypesInput):
		var phonType : Phonetics.PhoneticType = Phonetics.PhoneticType[Phonetics.PhoneticType.keys()[eachChecked]]
		cc.phonTypes.append(phonType)
	#Diacritics
	for eachChecked in get_menu_checked(phonDiacriticCommandInput):
		var nextName := phonNameInput.get_popup().get_item_text(eachChecked)
		cc.phonDiacriticCommand.append(nextName)
	#Vowel Rounding
	for eachChecked in get_menu_checked(phonVowelRoundPrefInput):
		cc.phonVowelRoundPref.append(eachChecked == 0)
	#Vowel Goal
	if phonVowelGoalToggle.button_pressed:
		cc.phonVowelGoal.append(Vector2(phonVowelGoalXInput.value, phonVowelGoalYInput.value))
	#Consonant Inputs
	for eachChecked in get_menu_checked(phonConsonantSoundInput):
		var phonType : Phonetics.PulCon.Sound = Phonetics.PulCon.Sound[Phonetics.PulCon.Sound.keys()[eachChecked]]
		cc.phonConsonantSound.append(phonType)
	for eachChecked in get_menu_checked(phonConsonantShapeInput):
		var phonType : Phonetics.Consonant.Shape = Phonetics.Consonant.Shape[Phonetics.Consonant.Shape.keys()[eachChecked]]
		cc.phonConsonantShape.append(phonType)
	for eachChecked in get_menu_checked(phonConsonantVoicedInput):
		var phonType : Phonetics.Consonant.Voiced = Phonetics.Consonant.Voiced[Phonetics.Consonant.Voiced.keys()[eachChecked]]
		cc.phonConsonantVoiced.append(phonType)
	#Tone Goal
	if phonToneGoalToggle.button_pressed:
		cc.phonToneGoal.append(phonToneGoalInput.value)
	### AP Items ###
	#Item Source Flags
	match itemSourcePrefInput.selected:
		0:
			cc.itemSourcePref = cc.SourcePref.NULL
		1:
			cc.itemSourcePref = cc.SourcePref.EXTERNAL
		2:
			cc.itemSourcePref = cc.SourcePref.LOCAL
	cc.itemQualityMulti = itemQualityMultiInput.value
	#Item Quality Flags
	for eachEntry in itemQualityFlagInputs.size():
		if itemQualityFlagInputs[eachEntry].button_pressed:
			cc.itemQualityFlags.append(eachEntry)
	return cc

func from_color_catagory(cc : ColorCatagory) -> void:
	### Basics ###
	nameInput.text = cc.name
	colorInput.color = cc.color
	descriptionInput.text = cc.description
	## Lookups ###
	#Color Word Weights
	remove_entries()
	for eachColorInput in cc.lookupTagsColor:
		var newEntry := add_pressed()
		newEntry.from_word_weight(eachColorInput)
	#Parts of Speech
	for eachPartInput in lookupTagsPartsInput:
		var isTicked := cc.lookupTagsParts.keys().has(eachPartInput.partName.to_lower())
		eachPartInput.set_enabled(isTicked)
		if isTicked:
			eachPartInput.set_value(cc.lookupTagsParts[eachPartInput.partName.to_lower()])
	### Phonetics ###
	#Names
	for eachChecked in phonNameInput.item_count:
		var popup := phonNameInput.get_popup()
		var nextName := phonNameInput.get_popup().get_item_text(eachChecked)
		popup.set_item_checked(eachChecked, cc.phonName.has(nextName))
	#Types
	for eachChecked in phonTypesInput.item_count:
		var popup := phonTypesInput.get_popup()
		var enumVal : Phonetics.PhoneticType = Phonetics.PhoneticType.values()[eachChecked]
		popup.set_item_checked(eachChecked, cc.phonTypes.has(enumVal))
	#Diacritics
	for eachChecked in phonDiacriticCommandInput.item_count:
		var popup := phonDiacriticCommandInput.get_popup()
		var nextName := phonDiacriticCommandInput.get_popup().get_item_text(eachChecked)
		popup.set_item_checked(eachChecked, cc.phonDiacriticCommand.has(nextName))
	#Vowel Rounding
	for eachChecked in phonVowelRoundPrefInput.item_count:
		var popup := phonVowelRoundPrefInput.get_popup()
		popup.set_item_checked(eachChecked, cc.phonVowelRoundPref.has(eachChecked == 0))
	#Vowel Goal
	if cc.phonVowelGoal.size() > 0:
		phonVowelGoalToggle.button_pressed = true
		vowel_goal_toggled(true)
		phonVowelGoalXInput.value = cc.phonVowelGoal[0].x
		phonVowelGoalYInput.value = cc.phonVowelGoal[0].y
		set_cursor_pos(cc.phonVowelGoal[0])
	else:
		phonVowelGoalToggle.button_pressed = false
		vowel_goal_toggled(false)
	#Consonant Inputs
	for eachChecked in phonConsonantSoundInput.item_count:
		var popup := phonConsonantSoundInput.get_popup()
		var enumVal : Phonetics.PulCon.Sound = Phonetics.PulCon.Sound.values()[eachChecked]
		popup.set_item_checked(eachChecked, cc.phonConsonantSound.has(enumVal))
	for eachChecked in phonConsonantShapeInput.item_count:
		var popup := phonConsonantShapeInput.get_popup()
		var enumVal : Phonetics.Consonant.Shape = Phonetics.Consonant.Shape.values()[eachChecked]
		popup.set_item_checked(eachChecked, cc.phonConsonantShape.has(enumVal))
	for eachChecked in phonConsonantVoicedInput.item_count:
		var popup := phonConsonantVoicedInput.get_popup()
		var enumVal : Phonetics.Consonant.Voiced = Phonetics.Consonant.Voiced.values()[eachChecked]
		popup.set_item_checked(eachChecked, cc.phonConsonantVoiced.has(enumVal))
	#Tone Goal
	phonToneGoalToggle.button_pressed = cc.phonToneGoal.size() > 0
	phonToneGoalInput.editable = phonToneGoalToggle.button_pressed
	if cc.phonToneGoal.size() > 0:
		phonToneGoalInput.value = cc.phonToneGoal[0]
	### AP Items ###
	#Item Source Flags
	match cc.itemSourcePref:
		cc.SourcePref.NULL:
			itemSourcePrefInput.select(0)
		cc.SourcePref.EXTERNAL:
			itemSourcePrefInput.select(1)
		cc.SourcePref.LOCAL:
			itemSourcePrefInput.select(2)
	itemQualityMultiInput.value = cc.itemQualityMulti
	#Item Quality Flags
	for eachEntry in itemQualityFlagInputs.size():
		itemQualityFlagInputs[eachEntry].button_pressed = cc.itemQualityFlags.has(eachEntry)

func json_save(path: String) -> void:
	var saveFile := FileAccess.open(path, FileAccess.WRITE)
	var cc := to_color_catagory()
	saveFile.store_string(JSON.stringify(cc.save_json(), "\t"))
	saveFile.close()

func res_save(path: String) -> void:
	ResourceSaver.save(to_color_catagory(), path)

func json_load(path: String) -> void:
	remove_entries()
	var saveFile := FileAccess.open(path, FileAccess.READ)
	var saveData = JSON.parse_string(saveFile.get_as_text())
	var cc := ColorCatagory.load_json(saveData)
	from_color_catagory(cc)
	saveFile.close()

func res_load(path: String) -> void:
	remove_entries()
	var saveFile := FileAccess.open(path, FileAccess.READ)
	var cc := ResourceLoader.load(path)
	from_color_catagory(cc)
	saveFile.close()
