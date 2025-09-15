extends Control
class_name WordPool

var wordsEnglish : Array[String] = []
@export var httpRequest : HTTPRequest
@export var requestCooldown : Timer
var gameCardsets : Dictionary[String, GameCardset]
var existingWords : Dictionary[String, NameFlags]
var fictionalWords : Dictionary[String, FictionalNameFlags]
var existingNames : Dictionary[String, NameData]
var allCards : Array[CardData]
var allowRepass : bool = true
var _wordQueue : PackedStringArray
var conn : ConnectionInfo
var awaitingDictionaryApi : bool

signal garbage_word(clearWord : String)
signal new_word_flags(newWord : String, newFlags : NameFlags)

#Setup words
func _ready() -> void:
	#Sourced from https://github.com/meetDeveloper/freeDictionaryAPI/blob/master/meta/wordList/english.txt
	var fileLoad : FileAccess = FileAccess.open("res://Resources/english.txt", FileAccess.READ)
	wordsEnglish.append_array(fileLoad.get_as_text().split("\n"))
	fileLoad.close()
	#Start AP
	Archipelago.AP_GAME_NAME = "Arcardelago"
	Archipelago.set_tags(["TextOnly"])
	Archipelago.ap_connect("localhost","38281","Smg065")
	Archipelago.connected.connect(on_connection)

func on_connection(inConn: ConnectionInfo, _json: Dictionary):
	conn = inConn
	conn.all_scout_cached.connect(scout_output)
	
	#Go over all the players
	for eachPlayer in conn.players:
		var currentSlot : NetworkSlot = eachPlayer.get_slot()
		#No teams or spectators
		if currentSlot.type == 1:
			#If there's no cardset for this game
			if not gameCardsets.has(currentSlot.game):
				var gameNameData : NameData = get_name_data(currentSlot.game)
				gameCardsets[currentSlot.game] = GameCardset.new(gameNameData)
	conn.load_locations()
	conn.force_scout_all()
	#print(json)

func scout_output():
	for eachEntry in conn._scout_cache:
		#Get all the information about this item
		var eachItem : NetworkItem = conn._scout_cache[eachEntry]
		var eachPlayer : NetworkPlayer = conn.get_player(eachItem.dest_player_id)
		#Get all the name data
		var playerName : String = eachPlayer.get_name()
		var itemNameData : NameData = get_name_data(eachItem.get_name())
		var cardset : GameCardset = gameCardsets[eachPlayer.get_slot().game]
		#Create card data from this information
		var cardData : CardData = CardData.new(eachItem, eachEntry, itemNameData, cardset, playerName)
		allCards.append(cardData)
	try_request()

func get_name_data(inName : String) -> NameData:
	if not existingNames.has(inName):
		var newNameData : NameData = NameData.new(inName, self)
		existingNames[inName] = newNameData
		if not new_word_flags.is_connected(newNameData.check_has_word):
			new_word_flags.connect(newNameData.check_has_word)
		return newNameData
	else:
		return existingNames[inName]

func try_get_word_flags(checkName : String) -> NameFlags:
	checkName = checkName.to_lower()
	if !existingWords.has(checkName):
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
				requestCooldown.start()
			#Too many requests
			429:
				requestCooldown.start()
			_:
				print(response_code)
		return
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var jsonOutput = json.get_data()
	var nameFlags : NameFlags = NameFlags.new(jsonOutput)
	existingWords[nameFlags.word] = nameFlags
	_wordQueue.erase(nameFlags.word)
	new_word_flags.emit(nameFlags.word, nameFlags)
	requestCooldown.start()

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
	if !fictionalWords.has(newWord):
		fictionalWords[newWord] = null

func fictional_names_check_existing():
	for eachFictional in fictionalWords:
		#Only worry about keyless words
		if fictionalWords[eachFictional] != null:
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
		fictionalWords[eachFictional] = FictionalNameFlags.new(eachFictional, fictWeights, fictRealNames, fictNameFlags, self)
	#Back to the word queue
	if _wordQueue.size() > 0 and allowRepass:
		allowRepass = false
		try_request()
	else:
		print("Done!")

func dictionary_api_delay() -> void:
	try_request()
