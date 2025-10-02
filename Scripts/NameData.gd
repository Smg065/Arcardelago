extends Resource
class_name NameData

var name : String
var words : PackedStringArray
var fictionalWords : PackedStringArray
var numbers : PackedInt32Array
var nameFlags : Array[NameFlagBase]
var uniquePhonetics : Dictionary
var _waitingForNameflags : bool = false
var _awaitingWords : PackedStringArray
var _flagOrderHint : PackedStringArray

signal all_words_found(fromData : NameData)

const PUNCTUATION : Dictionary[String, String] = {
	":" : "colon",
	";" : "semicolon",
	"\"" : "quote",
	"-" : "minus",
	"!" : "exclamation",
	"?" : "question",
	"." : "period",
	"/" : "slash",
	"\\" : "backslash",
	"(" : "bracket",
	")" : "bracket",
	"{" : "curly",
	"}" : "curly",
	"[" : "square",
	"]" : "square",
	"_" : "underscore",
	"+" : "plus",
	"$" : "money",
	"%" : "percent",
	"&" : "ampersand",
	"=" : "equal",
	"," : "comma",
	"`" : "apostrophe",
	"~" : "tilde", 
	"#" : "number", 
	"<" : "left", 
	">" : "right", 
	"@" : "at", 
	"^" : "up"
}

static func build(inName : String, wordPool : WordPool) -> NameData:
	var newNameData := NameData.new()
	#Remember this name
	newNameData.name = inName
	
	#Cleanup the name
	inName = inName.capitalize().to_lower()
	
	#Steal the punctuation marks and append them as words
	for eachKey in PUNCTUATION.keys():
		var eachChar : String = PUNCTUATION[eachKey]
		if inName.contains(eachKey):
			inName = inName.replace(eachKey, " ")
			newNameData.words.append(eachChar)
	
	#Split the name by spaces
	var splitName : PackedStringArray = inName.split(" ")
	for eachEntry in splitName:
		#Remove possesives
		if eachEntry.ends_with("'s"):
			eachEntry = eachEntry.trim_suffix("'s")
			newNameData.words.append("possessive")
		if eachEntry.is_valid_int():
			#Numbers
			newNameData.numbers.append(int(eachEntry))
		elif eachEntry != "":
			#Words
			newNameData.words.append(eachEntry)
			newNameData._flagOrderHint.append(eachEntry)
	
	#Get words that match from the wordpool
	for eachWord in newNameData.words.duplicate():
		#Is this a word?
		if wordPool.wordsEnglish.has(eachWord):
			#If the word pool has that flag
			var tryFlags = wordPool.try_get_word_flags(eachWord)
			if tryFlags != null:
				#Append it
				newNameData.nameFlags.append(tryFlags)
			else:
				newNameData._waitingForNameflags = true
				newNameData._awaitingWords.append(eachWord)
		#Empty words are not words
		elif eachWord != "":
			#Fictional words are words, keep them in mind
			wordPool.notify_fictional_word(eachWord)
			newNameData.fictionalWords.append(eachWord)
			newNameData.words.erase(eachWord)
	
	#Name Flags
	if newNameData._waitingForNameflags:
		wordPool.new_word_flags.connect(newNameData.check_has_word)
	wordPool.garbage_word.connect(newNameData.check_garbage_words)
	newNameData.get_phonetic_counts()
	return newNameData

func check_has_word(incomingWord : String, incomingFlags : NameFlagBase):
	#If this is a word you've been looking for
	if _awaitingWords.has(incomingWord):
		#Remove it as a word you're waiting for
		_awaitingWords.erase(incomingWord)
		#Add it to the flags if it's not already there
		if not nameFlags.has(incomingFlags):
			nameFlags.append(incomingFlags)
			#If this tagged as a "real word" but the incoming flags say otherwise
			if words.has(incomingWord):
				match incomingFlags.get_flag_type():
					NameFlagBase.FlagType.FICTIONAL_NAME_FLAG:
						words.erase(incomingWord)
						fictionalWords.append(incomingWord)
	try_awaited_clear()

func check_garbage_words(incomingWord : String):
	#Cleanup garbage words
	if fictionalWords.has(incomingWord):
		fictionalWords.erase(incomingWord)
	if words.has(incomingWord):
		words.erase(incomingWord)
	if _awaitingWords.has(incomingWord):
		_awaitingWords.erase(incomingWord)
	try_awaited_clear()

func try_awaited_clear():
	#Emit when you've gotten all awaited words
	if _awaitingWords.size() == 0:
		_waitingForNameflags = false
		all_words_found.emit(self)

func get_phonetic_counts():
	uniquePhonetics.clear()
	var allPhonetics : Array = []
	for eachFlag in nameFlags:
		allPhonetics.append_array(eachFlag.get_phonetics())
	for eachPhonetic in allPhonetics:
		if not uniquePhonetics.has(eachPhonetic):
			uniquePhonetics[eachPhonetic] = 1
		else:
			uniquePhonetics[eachPhonetic] += 1

func rich_text_unique_phonetics() -> PackedStringArray:
	var outStrings := PackedStringArray([])
	for eachPhonetic in uniquePhonetics:
		outStrings.append(eachPhonetic.rich_text(uniquePhonetics[eachPhonetic]))
	return outStrings

func get_parts_of_speech() -> PackedStringArray:
	var outParts : PackedStringArray
	for eachFlag in nameFlags:
		outParts.append_array(eachFlag.get_parts_of_speech())
	return outParts

func json_save():
	var saveOutput : Dictionary = {
		"name" : name,
		"words" : words,
		"fictionalWords" : fictionalWords,
		"numbers" : numbers
	}
	return saveOutput

static func json_load(inDict, gameData : GameData) -> NameData:
	var newNameData := NameData.new()
	newNameData.name = inDict["name"]
	newNameData.words = inDict["words"]
	newNameData.fictionalWords = inDict["fictionalWords"]
	newNameData.numbers = inDict["numbers"]
	for eachFlag in inDict["fictionalWords"]:
		newNameData.nameFlags.append(gameData.fictionalWords[eachFlag])
	for eachFlag in inDict["words"]:
		if not newNameData.fictionalWords.has(eachFlag):
			newNameData.nameFlags.append(gameData.existingWords[eachFlag])
		else:
			push_warning("In both dictionaries: %s" % eachFlag)
	newNameData.get_phonetic_counts()
	return newNameData
