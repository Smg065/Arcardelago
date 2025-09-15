extends Resource
class_name NameData

var name : String
var words : PackedStringArray
var numbers : PackedInt32Array
var nameFlags : Array[NameFlags]
var _waitingForNameflags : bool = false
var _awaitingWords : PackedStringArray

signal all_words_found(fromData : NameData)

const PUNCTUATION : Dictionary[int, String] = {
	ord(":") : "colon",
	ord(";") : "semicolon",
	ord("\"") : "quote",
	ord("-") : "minus",
	ord("!") : "exclamation",
	ord("?") : "question",
	ord(".") : "period",
	ord("/") : "slash",
	ord("\\") : "backslash",
	ord("(") : "bracket",
	ord(")") : "bracket",
	ord("{") : "curly",
	ord("}") : "curly",
	ord("[") : "square",
	ord("]") : "square",
	ord("_") : "underscore",
	ord("+") : "plus",
	ord("$") : "money",
	ord("%") : "percent",
	ord("&") : "ampersand",
	ord("=") : "equal",
	ord(",") : "comma",
	ord("`") : "apostrophe",
	ord("~") : "tilde", 
	ord("#") : "number", 
	ord("<") : "left", 
	ord(">") : "right", 
	ord("@") : "at", 
	ord("^") : "up"
}

func _init(inName : String, wordPool : WordPool) -> void:
	#Remember this name
	name = inName
	
	#Cleanup the name
	inName = inName.capitalize().to_lower()
	
	#Steal the punctuation marks and append them as words
	for eachKey in PUNCTUATION.keys():
		var eachChar : String = PUNCTUATION[eachKey]
		if inName.contains(eachChar):
			inName = inName.replace(eachChar, " ")
			words.append(eachChar)
	
	#Split the name by spaces
	var splitName : PackedStringArray = inName.split(" ")
	for eachEntry in splitName:
		if eachEntry.is_valid_int():
			#Numbers
			numbers.append(int(eachEntry))
		else:
			#Words
			words.append(eachEntry)
	
	#Get words that match from the wordpool
	for eachWord in words:
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
	
	#Name Flags
	if _waitingForNameflags:
		wordPool.new_word_flags.connect(check_has_word)

func check_has_word(incomingWord : String, incomingFlags : NameFlags):
	#If this is a word you've been looking for
	if _awaitingWords.has(incomingWord):
		#Remove it as a word you're waiting for
		_awaitingWords.erase(incomingWord)
		#Add it to the flags if it's not already there
		if not nameFlags.has(incomingFlags):
			nameFlags.append(incomingFlags)
	#Emit when you've gotten all awaited words
	if _awaitingWords.size() == 0:
		_waitingForNameflags = false
		all_words_found.emit(self)
