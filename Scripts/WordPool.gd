extends Control
class_name WordPool

var wordsEnglish : Array[String] = []
#Sourced from https://github.com/dwyl/english-words
@export var englishJson : Resource
@export var httpRequest : HTTPRequest
@export var requestCooldown : Timer
var existingWords : Dictionary[String, NameFlags]
var existingNames : Dictionary[String, NameData]
var allCards : Array[CardData]
var _wordQueue : PackedStringArray
var conn : ConnectionInfo
var awaitingDictionaryApi : bool

signal new_word_flags(newWord : String, newFlags : NameFlags)

#Setup words
func _ready() -> void:
	var stringified : String = FileAccess.get_file_as_string(englishJson.resource_path)
	wordsEnglish.append_array(JSON.parse_string(stringified).keys())
	Archipelago.AP_GAME_NAME = ""
	Archipelago.set_tags(["TextOnly"])
	Archipelago.ap_connect("localhost","38281","Smg065")
	Archipelago.connected.connect(on_connection)

func on_connection(inConn: ConnectionInfo, _json: Dictionary):
	conn = inConn
	conn.all_scout_cached.connect(scout_output)
	
	for eachPlayer in conn.players:
		var currentSlot : NetworkSlot = eachPlayer.get_slot()
		print(eachPlayer.name)
		print(currentSlot.game)
	conn.load_locations()
	conn.force_scout_all()
	#print(json)

func scout_output():
	for eachEntry in conn._scout_cache:
		#Get all the information about this item
		var eachItem : NetworkItem = conn._scout_cache[eachEntry]
		var eachLocation : APLocation = conn.get_location(eachEntry)
		var eachPlayer : NetworkPlayer = conn.get_player(eachItem.dest_player_id)
		#Get all the name data
		var playerName : String = eachPlayer.get_name()
		var itemNameData : NameData = get_name_data(eachItem.get_name())
		var locationNameData : NameData = get_name_data(eachLocation.name)
		var gameNameData : NameData = get_name_data(eachPlayer.get_slot().game)
		#Create card data from this information
		var cardData : CardData = CardData.new(eachItem, itemNameData, locationNameData, gameNameData, playerName)
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
		print(response_code)
		match response_code:
			404:
				print("Missing: " + _wordQueue[0])
				_wordQueue.remove_at(0)
				requestCooldown.start()
			#Too many requests
			429:
				requestCooldown.start()
		return
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var jsonOutput = json.get_data()
	var nameFlags : NameFlags = NameFlags.new(jsonOutput)
	existingWords[nameFlags.word] = nameFlags
	print("New Word: " + nameFlags.word)
	_wordQueue.erase(nameFlags.word)
	new_word_flags.emit(nameFlags.word, nameFlags)
	requestCooldown.start()

#Try to queue any other missing entries
func try_request():
	if _wordQueue.size() > 0:
		var currentStatus : HTTPClient.Status = httpRequest.get_http_client_status()
		print(currentStatus)
		var error = httpRequest.request("https://api.dictionaryapi.dev/api/v2/entries/en/" + _wordQueue[0])
		if error != OK:
			print("woops")

func dictionary_api_delay() -> void:
	try_request()
