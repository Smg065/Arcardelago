extends Control
class_name MainMenu

@export var playScene : PackedScene
@export var yamlScene : PackedScene

func play_pressed() -> void:
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
