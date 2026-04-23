extends Control
class_name MainMenu

@export var playScene : PackedScene
@export var yamlScene : PackedScene
@export var savesHBox : HBoxContainer
@export var filenameBox : LineEdit
@export var ipBox : LineEdit
@export var portBox : LineEdit
@export var slotBox : LineEdit
@export var passwordBox : LineEdit

func _ready() -> void:
	Archipelago.AP_GAME_NAME = "Cardelago"

func play_pressed() -> void:
	for eachChild in savesHBox.get_children():
		eachChild.queue_free()
	for eachSaveFile in GameData.get_all_save_files():
		savesHBox.add_child(eachSaveFile.visrep(self))

##Try to start a game using the inputed info
func new_game_connect():
	Persist.filename = filenameBox.text
	Persist.ip = ipBox.text
	Persist.port = portBox.text
	Persist.slot = slotBox.text
	Persist.password = passwordBox.text
	try_connect()

##Start a game using an existing save file
func save_connect(saveFile : SaveFile):
	saveFile.set_persist()
	try_connect()

func try_connect():
	#Start AP
	var strAr : Array[String] = []
	Archipelago.set_tags(strAr)
	Archipelago.ap_connect(Persist.ip, Persist.port, Persist.slot, Persist.password)
	Archipelago.connected.connect(on_connection)
	print("Trying to connect")

func on_connection(conn : ConnectionInfo, json : Dictionary):
	print("Hello world!")
	start_game()

func confirm_delete(saveFile : SaveFile):
	print("Delete save!")

func start_game() -> void:
	get_tree().change_scene_to_packed(playScene)

func yaml_button_pressed() -> void:
	get_tree().change_scene_to_packed(yamlScene)

func quit_pressed() -> void:
	get_tree().quit()

func fullscreen_pressed() -> void:
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func set_creator_pressed() -> void:
	pass # Replace with function body.

func awg_creator_pressed() -> void:
	pass # Replace with function body.

func custom_color_pressed() -> void:
	pass # Replace with function body.
