extends TextureRect
class_name WordGroupCreatorUI

@export var nameInput : LineEdit
@export var scoreInput : SpinBox
@export var wordEntryPrefab : PackedScene
@export var customColors : Array[ColorCatagory]
@export var entryHolder : VBoxContainer
@export var entries : Array[ColorWeightEntryUI]
@export var editorSaveButton : Button
@export var editorLoadButton : Button

func _ready() -> void:
	if OS.is_debug_build():
		editorSaveButton.show()
		editorLoadButton.show()

func add_pressed(startingEntry : bool = true) -> ColorWeightEntryUI:
	var cwe : ColorWeightEntryUI = wordEntryPrefab.instantiate()
	cwe.wordGroup = self
	entryHolder.add_child(cwe)
	entries.append(cwe)
	if startingEntry:
		cwe.create_new_entry()
		cwe.order_entries()
	cwe.set_shifts(shift_entry)
	cwe.erase_started.connect(remove_entry.bind(cwe))
	order_entries()
	return cwe

func remove_entries():
	for eachEntry in entries:
		eachEntry.queue_free()
	entries.clear()

func remove_entry(cwe : ColorWeightEntryUI):
	entries.erase(cwe)
	cwe.queue_free()
	order_entries()

func order_entries():
	for eachChild in entries:
		var newIndex : int = entries.find(eachChild)
		entryHolder.move_child(eachChild, newIndex)
		eachChild.set_shifts_enabled(newIndex > 0, newIndex < entries.size() - 1)

func shift_entry(targetUi : ColorWeightEntryUI, moveDir : int):
	var entryIndex : int = entries.find(targetUi)
	entries.remove_at(entryIndex)
	entries.insert(entryIndex + moveDir, targetUi)
	order_entries()

func from_arbitrary_word_group(awg : ArbitraryWordGroups):
	nameInput.text = awg.name
	scoreInput.value = awg.baseScore
	for eachEntry in awg.table:
		var entry := add_pressed(false)
		entry.from_color_word_data(eachEntry, customColors)
	order_entries()

func to_arbitrary_word_group() -> ArbitraryWordGroups:
	var awg := ArbitraryWordGroups.new()
	awg.name = nameInput.text
	awg.baseScore = scoreInput.value
	for eachEntry in entries:
		awg.table.append(eachEntry.to_color_word_data())
	return awg

func json_save(path: String) -> void:
	var saveFile := FileAccess.open(path, FileAccess.WRITE)
	var awg := to_arbitrary_word_group()
	saveFile.store_string(JSON.stringify(awg.save_json(), "\t"))
	saveFile.close()

func res_save(path: String) -> void:
	ResourceSaver.save(to_arbitrary_word_group(), path)

func json_load(path: String) -> void:
	remove_entries()
	var saveFile := FileAccess.open(path, FileAccess.READ)
	var saveData = JSON.parse_string(saveFile.get_as_text())
	var awg := ArbitraryWordGroups.new()
	awg.load_json(saveData)
	from_arbitrary_word_group(awg)
	saveFile.close()

func res_load(path: String) -> void:
	remove_entries()
	var saveFile := FileAccess.open(path, FileAccess.READ)
	var awg := ResourceLoader.load(path)
	from_arbitrary_word_group(awg)
	saveFile.close()
