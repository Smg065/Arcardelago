extends SubEntry
class_name ColorWeightEntryUI

@export var subentryPrefab : PackedScene
var subentries : Array[ColorWeightSubentryUI]
@export var entrySpot : VBoxContainer
var wordGroup : WordGroupCreatorUI

func create_new_entry() -> ColorWeightSubentryUI:
	var newEntry : ColorWeightSubentryUI = subentryPrefab.instantiate()
	subentries.append(newEntry)
	entrySpot.add_child(newEntry)
	newEntry.set_shifts(shift_entry)
	newEntry.erase_started.connect(remove_entry.bind(newEntry))
	newEntry.create_colors(wordGroup.customColors)
	new_min_size()
	return newEntry

func to_color_word_data() -> ColorWordData:
	var cwd := ColorWordData.new()
	cwd.word = $WordInput.text
	trim_dead_entries()
	for eachEntry in subentries:
		cwd.colorWeights.append(eachEntry.to_color_weight())
	return cwd

func from_color_word_data(cwd : ColorWordData, customColors):
	$WordInput.text = cwd.word
	for eachEntry in cwd.colorWeights:
		var newEntry := create_new_entry()
		newEntry.from_color_weight(eachEntry, customColors)

func trim_dead_entries():
	while subentries.has(null):
		subentries.erase(null)

func add_pressed() -> void:
	trim_dead_entries()
	create_new_entry()
	order_entries()

func remove_entry(targetUi : ColorWeightSubentryUI):
	subentries.erase(targetUi)
	targetUi.queue_free()
	trim_dead_entries()
	order_entries()
	new_min_size()

func new_min_size():
	custom_minimum_size.y = max(64.0 * subentries.size(), 64)

func shift_entry(targetUi : ColorWeightSubentryUI, moveDir : int):
	trim_dead_entries()
	var entryIndex : int = subentries.find(targetUi)
	subentries.remove_at(entryIndex)
	subentries.insert(entryIndex + moveDir, targetUi)
	order_entries()

func order_entries():
	for eachChild in subentries:
		var newIndex : int = subentries.find(eachChild)
		entrySpot.move_child(eachChild, newIndex)
		eachChild.set_shifts_enabled(newIndex > 0, newIndex < subentries.size() - 1)
