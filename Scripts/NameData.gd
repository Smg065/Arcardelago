extends Resource
class_name NameData

var name : String
var words : PackedStringArray
var fictionalWords : PackedStringArray
var numbers : PackedInt32Array
var nameFlags : Array[NameFlags]
var _waitingForNameflags : bool = false
var _awaitingWords : PackedStringArray

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

func _init(inName : String, wordPool : WordPool) -> void:
	#Remember this name
	name = inName
	
	#Cleanup the name
	inName = inName.capitalize().to_lower()
	
	#Steal the punctuation marks and append them as words
	for eachKey in PUNCTUATION.keys():
		var eachChar : String = PUNCTUATION[eachKey]
		if inName.contains(eachKey):
			inName = inName.replace(eachKey, " ")
			words.append(eachChar)
	
	#Split the name by spaces
	var splitName : PackedStringArray = inName.split(" ")
	for eachEntry in splitName:
		#Remove possesives
		if eachEntry.ends_with("'s"):
			eachEntry = eachEntry.trim_suffix("'s")
			words.append("possessive")
		if eachEntry.is_valid_int():
			#Numbers
			numbers.append(int(eachEntry))
		elif eachEntry != "":
			#Words
			words.append(eachEntry)
	
	#Get words that match from the wordpool
	for eachWord in words.duplicate():
		#Is this a word?
		if wordPool.wordsEnglish.has(eachWord):
			#If the word pool has that flag
			var tryFlags = wordPool.try_get_word_flags(eachWord)
			if tryFlags != null:
				#Append it
				nameFlags.append(tryFlags)
			else:
				_waitingForNameflags = true
				_awaitingWords.append(eachWord)
		#Empty words are not words
		elif eachWord != "":
			#Fictional words are words, keep them in mind
			wordPool.notify_fictional_word(eachWord)
			fictionalWords.append(eachWord)
			words.erase(eachWord)
	
	#Name Flags
	if _waitingForNameflags:
		wordPool.new_word_flags.connect(check_has_word)
	wordPool.garbage_word.connect(check_garbage_words)

func check_has_word(incomingWord : String, incomingFlags : NameFlags):
	#If this is a word you've been looking for
	if _awaitingWords.has(incomingWord):
		#Remove it as a word you're waiting for
		_awaitingWords.erase(incomingWord)
		#Add it to the flags if it's not already there
		if not nameFlags.has(incomingFlags):
			nameFlags.append(incomingFlags)
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
