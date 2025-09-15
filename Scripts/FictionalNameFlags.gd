class_name FictionalNameFlags

var name : String
var weights : PackedFloat32Array
var realNames : PackedStringArray
var nameFlags : Array[NameFlags]
var _awaitingWords : PackedStringArray
var _waitingForNameflags : bool = false

signal all_words_found(fictionalFlags : FictionalNameFlags)

func _init(newName : String, newWeights : PackedFloat32Array, newNames : PackedStringArray, newFlags : Array[NameFlags], wordPool : WordPool):
	#Defaults
	name = newName
	weights = newWeights
	realNames = newNames
	#Queue up all the word flags you're missing
	for eachFlag in newFlags:
		if !_awaitingWords.has(eachFlag.word) and realNames.has(eachFlag.word):
			_awaitingWords.append(eachFlag.word)
			_waitingForNameflags = true
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
