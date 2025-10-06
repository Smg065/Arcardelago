extends Control
class_name WordPool

@export_category("UI")
@export var progressControl : Control
@export var progressBar : ProgressBar
@export var progressLabel : Label
@export_category("Dictionary Connection Info")
var wordsEnglish : Array[String] = []
@export var httpRequest : HTTPRequest
@export var requestCooldown : Timer
var allowRepass : bool = true
var _wordQueue : PackedStringArray
var _initalWordQueueSize : int
var _secondWordQueueSize : int
var awaitingDictionaryApi : bool
@export_category("AP Connection Info")
@export var ip : String = "localhost"
@export var port : String = "38281"
@export var slot : String = "Smg065"
@export var password : String = ""
var conn : ConnectionInfo
var curCard : int = 0

signal garbage_word(clearWord : String)
signal new_word_flags(newWord : String, newFlags : NameFlagBase)

#Setup words
func _ready() -> void:
	#Sourced from https://github.com/meetDeveloper/freeDictionaryAPI/blob/master/meta/wordList/english.txt
	var fileLoad : FileAccess = FileAccess.open("res://Resources/english.txt", FileAccess.READ)
	wordsEnglish.append_array(fileLoad.get_as_text().split("\n"))
	fileLoad.close()
	#Start AP
	Archipelago.AP_GAME_NAME = "Arcardelago"
	Archipelago.set_tags([])
	Archipelago.ap_connect(ip, port, slot, password)
	Archipelago.connected.connect(on_connection)

func on_connection(inConn: ConnectionInfo, json: Dictionary):
	conn = inConn
	conn.new_scouts_cached.connect(scouts_updated)
	var gameInfo = GameData.find_valid_game(ip, port, slot, password)
	if gameInfo != "":
		Persist.game = GameData.json_load(gameInfo)
		Persist.hold_server_data(json["slot_data"])
		get_tree().change_scene_to_file("res://WorldMap.tscn")
	else:
		build_new_game(json)

#Create a new game if the JSON game key can't find something similar
func build_new_game(json: Dictionary):
	Persist.game = GameData.new()
	#Go over all the players
	for eachPlayer in conn.players:
		var currentSlot : NetworkSlot = eachPlayer.get_slot()
		#No teams or spectators
		if currentSlot.type == 1:
			#If there's no cardset for this game
			if not Persist.game.gameCardsets.has(currentSlot.game):
				var gameNameData : NameData = get_name_data(currentSlot.game)
				Persist.game.gameCardsets[currentSlot.game] = GameCardset.build(gameNameData)
				Persist.game.gameCardsets[currentSlot.game].players.append(eachPlayer.name)
			else:
				Persist.game.gameCardsets[currentSlot.game].players.append(eachPlayer.name)
	conn.load_locations()
	var locationIds : Array[int] = []
	locationIds.append_array(conn.slot_locations.keys())
	Persist.hold_server_data(json["slot_data"])
	build_enemies(json["slot_data"]["enemies"])
	Archipelago.send_command("LocationScouts", {"locations": locationIds, "create_as_hint": 0})

func scouts_updated():
	print(conn._scout_cache.size())
	if conn._scout_cache.size() == 120:
		conn.new_scouts_cached.disconnect(scouts_updated)
		scouts_to_cards()

func build_enemies(enemies : Array):
	for eachEnemy in enemies:
		var eachPlayer = conn.get_player(int(eachEnemy[0]))
		var local = eachPlayer == conn.get_player()
		var playerName : String = eachPlayer.name
		var itemNameData : NameData = get_name_data(eachEnemy[1])
		var cardset : GameCardset = Persist.game.gameCardsets[eachPlayer.get_slot().game]
		#Create card data from this information
		var cardData : CardData = CardData.build(eachEnemy[2], -1, itemNameData, cardset, playerName, local, true)
		Persist.game.allCards.append(cardData)

func scouts_to_cards():
	for eachEntry in conn._scout_cache:
		#Get all the information about this item
		var eachItem : NetworkItem = conn._scout_cache[eachEntry]
		var eachPlayer : NetworkPlayer = conn.get_player(eachItem.dest_player_id)
		#Get all the name data
		var playerName : String = eachPlayer.get_name()
		var itemNameData : NameData = get_name_data(eachItem.get_name())
		var cardset : GameCardset = Persist.game.gameCardsets[eachPlayer.get_slot().game]
		#Create card data from this information
		var cardData : CardData = CardData.build(eachItem.flags, eachEntry, itemNameData, cardset, playerName, eachItem.is_local())
		Persist.game.allCards.append(cardData)
	_initalWordQueueSize = _wordQueue.size()
	progressBar.max_value = _initalWordQueueSize + Persist.game.fictionalWords.size()
	progressLabel.text = "Calling Dictionary API..."
	update_progress_visual()
	try_request()

func get_name_data(inName : String) -> NameData:
	if not Persist.game.existingNames.has(inName):
		var newNameData : NameData = NameData.build(inName, self)
		Persist.game.existingNames[inName] = newNameData
		if not new_word_flags.is_connected(newNameData.check_has_word):
			new_word_flags.connect(newNameData.check_has_word)
		return newNameData
	else:
		return Persist.game.existingNames[inName]

func try_get_word_flags(checkName : String) -> NameFlags:
	checkName = checkName.to_lower()
	if !Persist.game.existingWords.has(checkName):
		if !_wordQueue.has(checkName):
			_wordQueue.append(checkName)
	return null

func dictionary_http_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		match response_code:
			404:
				wordsEnglish.erase(_wordQueue[0])
				#Repasses let you do this again
				if allowRepass:
					notify_fictional_word(_wordQueue[0])
				else:
					garbage_word.emit(_wordQueue[0])
				_wordQueue.remove_at(0)
				update_progress_visual()
				requestCooldown.start()
			#Too many requests
			429:
				requestCooldown.start()
			_:
				print("Response Code: " + str(response_code))
				requestCooldown.start(10)
		return
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var jsonOutput = json.get_data()
	var nameFlags : NameFlags = NameFlags.build(jsonOutput)
	Persist.game.existingWords[nameFlags.word] = nameFlags
	_wordQueue.erase(nameFlags.word)
	new_word_flags.emit(nameFlags.word, nameFlags)
	requestCooldown.start()
	update_progress_visual()

#Try to queue any other missing entries
func try_request():
	if _wordQueue.size() > 0:
		var currentStatus : HTTPClient.Status = httpRequest.get_http_client_status()
		if currentStatus != 0:
			return
		var error = httpRequest.request("https://api.dictionaryapi.dev/api/v2/entries/en/" + _wordQueue[0])
		if error != OK:
			print("HTTP Request Failed!")
	else:
		fictional_names_check_existing()

func notify_fictional_word(newWord : String):
	if !Persist.game.fictionalWords.has(newWord):
		Persist.game.fictionalWords[newWord] = null

func fictional_names_check_existing():
	for eachFictional in Persist.game.fictionalWords:
		#Only worry about keyless words
		if Persist.game.fictionalWords[eachFictional] != null:
			continue
		var fictWeights : PackedFloat32Array
		var fictRealNames : PackedStringArray
		var fictNameFlags : Array[NameFlags]
		
		#Hybridized fictional words
		if eachFictional.length() >= 5:
			for charIndex in eachFictional.length() - 1:
				#For each word half
				var prefixWord : String = eachFictional.substr(0, charIndex + 1)
				var suffixWord : String = eachFictional.substr(charIndex + 1)
				#Do both these words exist?
				if wordsEnglish.has(prefixWord) and wordsEnglish.has(suffixWord):
					#Append them both to the list
					fictWeights.append(1)
					fictWeights.append(1)
					fictRealNames.append(prefixWord)
					fictRealNames.append(suffixWord)
					#Get any flags that already exist
					var prefixHasFlags = try_get_word_flags(prefixWord)
					if prefixHasFlags != null:
						fictNameFlags.append(prefixHasFlags)
					#Get any flags that already exist
					var suffixHasFlags = try_get_word_flags(suffixWord)
					if suffixHasFlags != null:
						fictNameFlags.append(suffixHasFlags)
		
		#Find the most similar words
		var highestSimilarity : float = -1
		var sameSimilarity : PackedStringArray
		for eachReal in wordsEnglish:
			var eachSimilarity : float = eachReal.similarity(eachFictional.to_lower())
			#Words that are very similar in value are grouped together
			if is_equal_approx(highestSimilarity, eachSimilarity):
				sameSimilarity.append(eachReal)
			#Words that are more similar example replace the previous list
			elif highestSimilarity < eachSimilarity:
				highestSimilarity = eachSimilarity
				sameSimilarity.clear()
				sameSimilarity.append(eachReal)
			#Seperately, is there a whole real word in there (that's more than 3 letters)?
			if eachReal.length() >= 4 and eachFictional.contains(eachReal):
				#If it's already found that hybradized name, don't bother
				if !fictRealNames.has(eachReal):
					#Otherwise, add it by weight of the percent of word that has it
					var wordPercent : float = eachReal.length() / float(eachFictional.length())
					fictWeights.append(wordPercent)
					fictRealNames.append(eachReal)
					#Get any flags that already exist
					var hasFlags = try_get_word_flags(eachReal)
					if hasFlags != null:
						fictNameFlags.append(hasFlags)
		
		#If it surpasses the .85% margin
		if highestSimilarity >= .85:
			#Get all words close enough to work
			for eachWord in sameSimilarity:
				#Weights coorelate to names
				fictWeights.append(highestSimilarity)
				fictRealNames.append(eachWord)
				#Get any flags that already exist
				var hasFlags = try_get_word_flags(eachWord)
				if hasFlags != null:
					fictNameFlags.append(hasFlags)
		var newFictFlags : FictionalNameFlags = FictionalNameFlags.build(eachFictional, fictWeights, fictRealNames, fictNameFlags, self)
		Persist.game.fictionalWords[eachFictional] = newFictFlags
		new_word_flags.emit(eachFictional, newFictFlags)
	#Back to the word queue
	if _wordQueue.size() > 0 and allowRepass:
		_secondWordQueueSize = _wordQueue.size()
		progressBar.max_value = _initalWordQueueSize + _secondWordQueueSize
		progressLabel.text = "Recalling Dictionary API..."
		allowRepass = false
		try_request()
	else:
		save_game_as_new()

func save_game_as_new():
	Persist.game.save_as_file(ip, port, slot, password)
	get_tree().change_scene_to_file("res://WorldMap.tscn")

func dictionary_api_delay() -> void:
	try_request()

func update_progress_visual() -> void:
	if allowRepass:
		progressBar.value = _initalWordQueueSize - _wordQueue.size()
	else:
		progressBar.value = _initalWordQueueSize + _secondWordQueueSize - _wordQueue.size()
