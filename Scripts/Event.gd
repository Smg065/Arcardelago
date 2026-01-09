extends GameScreen
class_name EventScreen

var eventTable : Dictionary[String, EventNodeData]
var colorTables : Array[Dictionary] = [{"total" : 0, "entries" : {}}, {"total" : 0, "entries" : {}}, {"total" : 0, "entries" : {}}, {"total" : 0, "entries" : {}}, {"total" : 0, "entries" : {}}, {"total" : 0, "entries" : {}}]

@export var eventImage : TextureRect
@export var buttonVBox : VBoxContainer
@export var eventLabel : RichTextLabel

func _init() -> void:
	colorTables.resize(6)
	recursive_event_folder_search("res://Resources/Events/")

##Get all files in the folders that are events and append them to the lookup table
func recursive_event_folder_search(inDirectory : String):
	var thisFolder : DirAccess = DirAccess.open(inDirectory)
	if thisFolder == null:
		push_error("No path for the events!")
		return
	thisFolder.list_dir_begin()
	var filePath := thisFolder.get_next()
	while filePath != "":
		if thisFolder.current_is_dir():
			recursive_event_folder_search(filePath)
			filePath = thisFolder.get_next()
			continue
		if !filePath.ends_with(".gd"):
			filePath = thisFolder.get_next()
			continue
		var eachFile := load(inDirectory + filePath)
		if eachFile == null:
			filePath = thisFolder.get_next()
			continue
		var eachEvent : EventNodeData = eachFile.new()
		pack_event_to_colors(eachEvent)
		filePath = thisFolder.get_next()

##Stores an event and its weights to a given color entry
func pack_event_to_colors(inEvent : EventNodeData):
	eventTable[inEvent.eventName] = inEvent
	for eachColor in colorTables.size():
		print(pow(2, eachColor))
		if inEvent.eventColors & int(pow(2, eachColor)):
			colorTables[eachColor].entries[inEvent.eventName] = inEvent.eventWeight
			colorTables[eachColor].total += inEvent.eventWeight

##Sets if this screen is active in the map viewer or not
func set_active(nState : bool, nInfo : Dictionary):
	super(nState, nInfo)
	if !nState:
		return
	if nInfo["Region"] == 0:
		return
	var region : int = nInfo["Region"] - 1
	var table : Dictionary = colorTables[region].entries
	var weightedRoll := randi_range(1, colorTables[region].total)
	for entry in table:
		weightedRoll -= table[entry]
		if weightedRoll <= 0:
			setup_event(eventTable[entry])
			return

##Sets an event up based on the entry
func setup_event(eventToSetup : EventNodeData):
	eventImage.texture = eventToSetup.eventImage
	if eventToSetup.eventOptions.size() == 0:
		eventToSetup.add_exit_button()
	#Empty out the previous event data
	for eachChild in buttonVBox.get_children():
		eachChild.queue_free()
	#Fill in the new event
	for eachButton in eventToSetup.construct_buttons(self):
		buttonVBox.add_child(eachButton)
	eventLabel.text = eventToSetup.eventText

##Goes back to the overworld
func exit_event():
	var gameRoot : GameRoot = get_parent()
	gameRoot.clear_map_pip()
	gameRoot.switch_scenes()
