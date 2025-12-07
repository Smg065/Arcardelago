extends Resource
##The template for map-based events.
class_name EventNodeData

##The regions this event can show up in
@export_flags("Red", "Green", "Violet", "Orange", "Blue", "Yellow") var eventColors : int
##The name of the event
@export var eventName = "DEFAULT"
##The entries this event has in the weight pool
@export var eventWeight = 10
##The lowest difficulty the event can appear in
@export_range(0, 2) var eventMinDifficulty = 0
##The highest difficulty the event can appear in
@export_range(0, 2) var eventMaxDifficulty = 2
##The image to use for the background of this event
@export var eventImage : Texture2D
##The text for the event
@export_multiline var eventText : String
##The event's strings and callables. Used to construct the options.
var eventOptions : Dictionary[String, Callable]

##Builds all buttons with the given commands
func construct_buttons(eventScreen : EventScreen) -> Array[Button]:
	var output : Array[Button] = []
	for eachEntry in eventOptions:
		var eachButton : Button = Button.new()
		eachButton.pressed.connect(eventOptions[eachEntry].bind(eventScreen))
		eachButton.text = eachEntry
		output.append(eachButton)
	return output

##Adds an exit button to the event options
func add_exit_button(exitName : String = "Exit"):
	eventOptions[exitName] = exit

##Default exit option
func exit(eventScreen : EventScreen):
	eventScreen.exit_event()
