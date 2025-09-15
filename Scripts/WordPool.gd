extends Control
class_name WordPool

var wordsEnglish : Array[String] = []
#Sourced from https://github.com/dwyl/english-words
@export var englishJson : Resource
@export var httpRequest : HTTPRequest
var existingWords : Dictionary[String, NameFlags]
var wordQueue : PackedStringArray
var conn : ConnectionInfo

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
		var eachItem : NetworkItem = conn._scout_cache[eachEntry]
		var eachLocation : APLocation = conn.get_location(eachEntry)
		print(eachLocation.name + ": " + eachItem.get_name())
	print("All scouted!")

func try_get_word_flags(checkName : String) -> NameFlags:
	checkName = checkName.to_lower()
	if !existingWords.has(checkName):
		if !wordQueue.has(checkName):
			wordQueue.append(checkName)
	return null

func dictionary_http_request_completed(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var jsonOutput = json.get_data()
	var nameFlags : NameFlags = NameFlags.new(jsonOutput)
	existingWords[nameFlags.word] = nameFlags
	print("New Word: " + nameFlags.word)
	wordQueue.erase(nameFlags.word)
	try_request()

func try_request():
	#Try to queue any other missing entries
	if wordQueue.size() > 0:
		var error = httpRequest.request("https://api.dictionaryapi.dev/api/v2/entries/en/" + wordQueue[0])
		if error != OK:
			print("woops")
