extends Control
class_name CardScrollbox

@export var flow : HFlowContainer
@export var cardUi : PackedScene
@export var minSize : int = 256
@export var filtersMenu : MenuButton

func _ready() -> void:
	setup_filter()

func set_card_scale(newMin : int):
	minSize = newMin
	for eachChild in flow.get_children():
		eachChild.set_min_from_height(minSize)

func zoom_changed(value_changed: bool) -> void:
	if value_changed:
		set_card_scale($Zoom.value)

func setup_filter():
	#Set the filters toggles to work
	filtersMenu.get_popup().index_pressed.connect(toggle_filter)
	#Make sure you're connected
	if Archipelago.is_not_connected():
		push_error("No AP connection!")
		return false
	#Add the game and players to the filters
	var popup := filtersMenu.get_popup()
	var allGames : PackedStringArray
	var allPlayers : PackedStringArray
	for eachPlayer in Archipelago.conn.players:
		allPlayers.append(eachPlayer.get_name())
		var gameName := eachPlayer.get_slot().game
		if !allGames.has(gameName):
			allGames.append(gameName)
	for eachEntry in allGames:
		popup.add_check_item(eachEntry)
	popup.add_separator("Players")
	for eachEntry in allPlayers:
		popup.add_check_item(eachEntry)
	for eachEntry in 20:
		var newSlot : CardUI = cardUi.instantiate()
		flow.add_child(newSlot)
		newSlot.build(Persist.game.allCards.pick_random())
	set_card_scale(minSize)

func toggle_filter(filterIndex : int):
	var popup := filtersMenu.get_popup()
	popup.set_item_checked(filterIndex, !popup.is_item_checked(filterIndex))
