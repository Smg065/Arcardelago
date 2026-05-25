class_name SaveFile

var aplock: APLock = APLock.new()
var creds: APCredentials = APCredentials.new()
var filename := "NULL"

func read(file: FileAccess) -> bool:
	if not aplock.read(file):
		return false
	if not creds.read(file):
		return false
	if file.get_error():
		return false
	return true

func write(file: FileAccess) -> bool:
	if not aplock.write(file):
		return false
	if not creds.write(file):
		return false
	return true

func clear() -> void:
	aplock = APLock.new()
	creds = APCredentials.new()

func visrep(mainMenu : MainMenu) -> Panel:
	var panel := Panel.new()
	var vBox := VBoxContainer.new()
	panel.add_child(vBox)
	panel.custom_minimum_size = Vector2i.RIGHT * 256
	var filenameLabel := Label.new()
	var usernameLabel := Label.new()
	var ipLabel := Label.new()
	vBox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vBox.add_child(filenameLabel)
	filenameLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	filenameLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vBox.add_child(usernameLabel)
	usernameLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	usernameLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vBox.add_child(ipLabel)
	ipLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ipLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	usernameLabel.text = aplock.slot_name
	ipLabel.text = creds.ip
	
	var portIpBox := HBoxContainer.new()
	portIpBox.alignment = BoxContainer.ALIGNMENT_CENTER
	var portEdit := LineEdit.new()
	var portLabel := Label.new()
	vBox.add_child(portIpBox)
	portIpBox.add_child(portLabel)
	portIpBox.add_child(portEdit)
	portLabel.text = "Port: "
	portEdit.text = creds.port
	
	var playDeleteBox := HBoxContainer.new()
	vBox.add_child(playDeleteBox)
	var playButton := Button.new()
	var deleteButton := Button.new()
	playDeleteBox.add_child(playButton)
	playButton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	playDeleteBox.add_child(deleteButton)
	deleteButton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	playButton.text = "Play"
	playButton.pressed.connect(mainMenu.save_connect.bind(self))
	deleteButton.text = "Delete"
	deleteButton.pressed.connect(mainMenu.confirm_delete.bind(self))
	return panel

##Setup the persistant data to use the creds
func set_persist():
	Persist.filename = filename
	Persist.ip = creds.ip
	Persist.port = creds.port
	Persist.slot = creds.slot
	Persist.password = creds.pwd
