extends Resource
class_name NameData

var name : String
var words : PackedStringArray
var fictionalWords : PackedStringArray
var numbers : PackedInt32Array
var nameFlags : Array[NameFlagBase]
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

func build_rich_text_labels() -> Dictionary[String, RichTextLabel]:
	var richTextFullName : String = name
	var richTextPhonetics : String
	var richTextSynonyms : String = ""
	var richTextAntonyms : String = ""
	var replaceFlagsName = []
	var replaceFlagsPhonemics = []
	for eachFlag in nameFlags:
		var startIndex : int = richTextFullName.findn(eachFlag.word)
		if startIndex != -1:
			var replaceStr = richTextFullName.substr(startIndex, eachFlag.word.length())
			var insertOffset : int = 0
			if startIndex != 0:
				insertOffset = richTextFullName.count("%s", 0, startIndex)
			replaceFlagsName.insert(insertOffset, eachFlag.rich_text_name(replaceStr))
			replaceFlagsPhonemics.insert(insertOffset, eachFlag.rich_text_phonetics())
			richTextSynonyms += "\n".join(eachFlag.get_synonyms())
			richTextAntonyms += "\n".join(eachFlag.get_antonyms())
			richTextFullName = replace_first(richTextFullName, eachFlag.word, "%s")
	richTextFullName = richTextFullName % replaceFlagsName
	richTextPhonetics = "  ".join(replaceFlagsPhonemics)
	richTextSynonyms = "[color=GREEN]" + richTextSynonyms + "[/color]"
	richTextAntonyms = "[color=RED]" + richTextAntonyms + "[/color]"
	var outDict : Dictionary[String,RichTextLabel] = {
		"name" : build_rich_text_label(richTextFullName, 32),
		"phonetics" : build_rich_text_label(richTextPhonetics, 24),
		"synonyms" : build_rich_text_label(richTextSynonyms, 16),
		"antonyms" : build_rich_text_label(richTextAntonyms, 16)
	}
	return outDict

static func replace_first(from : String, what: String, forwhat : String) -> String:
	var index := from.findn(what)
	if index == -1:
		return from
	return from.substr(0, index) + forwhat + from.substr(what.length() + index)

func build_rich_text_label(inText : String, textSize : int) -> RichTextLabel:
	var newRichText := RichTextLabel.new()
	newRichText.text = "[font_size=%d]%s[/font_size]" % [textSize, inText]
	newRichText.bbcode_enabled = true
	newRichText.fit_content = true
	newRichText.autowrap_mode = TextServer.AUTOWRAP_OFF
	return newRichText

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
	for eachFlag in inDict["words"]:
		newNameData.nameFlags.append(gameData.existingWords[eachFlag])
	for eachFlag in inDict["fictionalWords"]:
		newNameData.nameFlags.append(gameData.fictionalWords[eachFlag])
	return newNameData
