extends Control
class_name CardScrollbox

@export var flow : HFlowContainer
@export var cardUi : PackedScene
@export var minSize : int = 256
@export var filtersMenu : MenuButton
var battleCards : Array[CardData]

func _ready() -> void:
	Persist.deck_changed.connect(show_current)
	show_current()
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
	set_card_scale(minSize)

##Make the Card Scrollbox display all card information that you have
func show_current():
	var previousCards : Array[CardData]
	previousCards.append_array(battleCards)
	for eachCardUi in flow.get_children():
		previousCards.append_array(eachCardUi.all_card_data())
	#Calculate the cards you will gain and lose based on the difference between the two
	for eachCard in Persist.currentCards:
		#Cards to remove are previous cards lacking all current cards
		if previousCards.has(eachCard):
			previousCards.erase(eachCard)
			continue
		#Add cards that are not in the previous card list
		else:
			add_card_from_data(eachCard)
	#Any cards the previous cards did have and are not in the current cards get removed
	for eachCard in previousCards:
		remove_card_from_data(eachCard)
	sort_children()

##Add a card to the scrollbox
func add_card_from_data(nCard : CardData):
	battleCards.erase(nCard)
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
	var allChildren := flow.get_children()
	nCardUI.shift_parent(flow)
	for allData in nCardUI.all_card_data():
		battleCards.erase(allData)
	for eachChild in allChildren:
		if nCardUI.cardData.is_comparable(eachChild.cardData):
			var data := nCardUI.extract_data()
			eachChild.compressedCardData.append_array(data)
			eachChild.new_compression_size()
			eachChild.update_compressed_vis()
			eachChild.set_stack_multi(false)
			return
	nCardUI.set_min_from_height(minSize)
	nCardUI.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	nCardUI.set_stack_multi(false)

##Remove card data from the scrollbox
func remove_card_from_data(nCard : CardData):
	for eachChild in flow.get_children():
		var eachCard : CardUI = eachChild as CardUI
		if eachCard.try_remove_card(nCard):
			return

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

##Sort the children of the flowbox alphabetically
func sort_children():
	var allChildren := flow.get_children()
	if allChildren.size() == 0:
		return
	allChildren.sort_custom(func(a: CardUI, b: CardUI): return 0 > a.cardName.naturalnocasecmp_to(b.cardName))
	for eachChild in allChildren:
		flow.remove_child(eachChild)
	for eachChild in allChildren:
		flow.add_child(eachChild)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var dict : Dictionary = data as Dictionary
	if !dict.has("IsArcardelago"):
		return false
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var inCard : CardUI = data["CardUI"]
	#Self drops just kick back
	if inCard in flow.get_children():
		return
	add_card_from_ui_card(inCard)
	sort_children()
