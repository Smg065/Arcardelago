extends NameFlagBase
class_name FictionalNameFlags

var weights : PackedFloat32Array
var realNames : PackedStringArray
var nameFlags : Array[NameFlags]
var _awaitingWords : PackedStringArray
var _waitingForNameflags : bool = false

signal all_words_found(fictionalFlags : FictionalNameFlags)

static func build(newName : String, newWeights : PackedFloat32Array, newNames : PackedStringArray, newFlags : Array[NameFlags], wordPool : WordPool) -> FictionalNameFlags:
	var newFictFlags = FictionalNameFlags.new()
	#Defaults
	newFictFlags.word = newName
	newFictFlags.weights = newWeights
	newFictFlags.realNames = newNames
	#Queue up all the word flags you're missing
	for eachFlag in newFlags:
		if !newFictFlags._awaitingWords.has(eachFlag.word) and newFictFlags.realNames.has(eachFlag.word):
			newFictFlags._awaitingWords.append(eachFlag.word)
			newFictFlags._waitingForNameflags = true
	if newFictFlags._waitingForNameflags:
		wordPool.new_word_flags.connect(newFictFlags.check_has_word)
	wordPool.garbage_word.connect(newFictFlags.check_garbage_words)
	return newFictFlags

func check_has_word(incomingWord : String, incomingFlags : NameFlagBase):
	#If this is a word you've been looking for
	if _awaitingWords.has(incomingWord):
		#Remove it as a word you're waiting for
		_awaitingWords.erase(incomingWord)
		#Add it to the flags if it's not already there
		if not nameFlags.has(incomingFlags):
			nameFlags.append(incomingFlags)
	try_awaited_clear()

func get_phonetics() -> Array:
	var phonetics : Array
	for eachFlag in nameFlags:
		phonetics.append_array(eachFlag.get_phonetics())
	return phonetics

func get_synonyms() -> PackedStringArray:
	var synonyms := PackedStringArray([])
	for eachFlag in nameFlags:
		synonyms.append_array(eachFlag.synonyms)
	return synonyms

func get_antonyms() -> PackedStringArray:
	var antonyms := PackedStringArray([])
	for eachFlag in nameFlags:
		antonyms.append_array(eachFlag.antonyms)
	return antonyms

func get_parts_of_speech() -> PackedStringArray:
	var partsOfSpeech := PackedStringArray([])
	for eachFlag in nameFlags:
		partsOfSpeech.append_array(eachFlag.partsOfSpeech)
	return partsOfSpeech

func check_garbage_words(incomingWord : String):
	#Cleanup garbage words
	while realNames.has(incomingWord):
		weights.remove_at(realNames.find(incomingWord))
		realNames.erase(incomingWord)
	if _awaitingWords.has(incomingWord):
		_awaitingWords.erase(incomingWord)
	try_awaited_clear()

func try_awaited_clear():
	#Emit when you've gotten all awaited words
	if _awaitingWords.size() == 0:
		_waitingForNameflags = false
		all_words_found.emit(self)

func json_save():
	var saveOutput : Dictionary = {
		"word" : word,
		"weights" : weights,
		"realNames" : realNames
	}
	return saveOutput

static func json_load(inDict, gameData : GameData) -> FictionalNameFlags:
	var newFictFlags = FictionalNameFlags.new()
	newFictFlags.word = inDict["word"]
	newFictFlags.weights = inDict["weights"]
	newFictFlags.realNames = inDict["realNames"]
	for eachEntry in newFictFlags.realNames:
		newFictFlags.nameFlags.append(gameData.existingWords[eachEntry])
	return newFictFlags

func get_flag_type():
	return FlagType.FICTIONAL_NAME_FLAG

func get_score(baseColor : ColorCatagory) -> float:
	var outScore : float = 0
	#You only get the amount of score based to the size
	for index in weights.size():
		outScore += nameFlags[index].get_score(baseColor) * weights[index]
	return outScore
