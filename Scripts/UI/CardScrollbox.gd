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
	show_current()
	set_card_scale(minSize)

func show_current():
	for eachCard in Persist.game.allCards:
		if eachCard.enemyCard:
			continue
		add_card_from_data(eachCard)

##Add a card to the scrollbox
func add_card_from_data(nCard : CardData):
	#Try to compress it into other cards
	for eachChild in flow.get_children():
		var eachCard : CardUI = eachChild as CardUI
		if eachCard.try_compress_card(nCard):
			return
	#If there are no other cards, create one
	var newSlot : CardUI = cardUi.instantiate()
	flow.add_child(newSlot)
	newSlot.build(nCard)

##Add a card from an existing card data
func add_card_from_ui_card(nCardUI : CardUI):
	nCardUI.shift_parent(flow)
	nCardUI.set_min_from_height(minSize)
	nCardUI.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

##One of the filters got toggled
func toggle_filter(filterIndex : int):
	var popup := filtersMenu.get_popup()
	popup.set_item_checked(filterIndex, !popup.is_item_checked(filterIndex))
	filter_items()

##Apply the new filter
func filter_items():
	var popup := filtersMenu.get_popup()
	var filterCommands : Dictionary[String, Array]
	var filterCatagory : String
	#Get the filter data
	for eachFilter in popup.item_count:
		if popup.is_item_checkable(eachFilter):
			if popup.is_item_checked(eachFilter):
				filterCommands = PD.append_dict_entry(filterCommands, filterCatagory, popup.get_item_text(eachFilter))
		elif popup.is_item_separator(eachFilter):
			filterCatagory = popup.get_item_text(eachFilter)
	for eachChild in flow.get_children():
		var eachCard : CardUI = eachChild as CardUI
		eachCard.filter(filterCommands)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var dict : Dictionary = data as Dictionary
	if !dict.has("IsArcardelago"):
		return false
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var inCard : CardUI = data["CardUI"]
	add_card_from_ui_card(inCard)
