extends NameFlagBase
class_name NameFlags

var phonetics : PackedStringArray
var deconstructedPhonetics : Array[Dictionary]
var synonyms : PackedStringArray
var antonyms : PackedStringArray
var partsOfSpeech : PackedStringArray
var definitions : PackedStringArray
var examples : PackedStringArray
var audioUrls : PackedStringArray

static func build(jsonData : Array) -> NameFlags:
	var newFlags = NameFlags.new()
	newFlags.word = jsonData[0]["word"]
	for eachEntry in jsonData:
		newFlags.overlapping_words(eachEntry)
	#Cleanup Packed String Arrays
	newFlags.phonetics = cleanup_packed_string(newFlags.phonetics)
	newFlags.synonyms = cleanup_packed_string(newFlags.synonyms)
	newFlags.antonyms = cleanup_packed_string(newFlags.antonyms)
	newFlags.partsOfSpeech = cleanup_packed_string(newFlags.partsOfSpeech)
	newFlags.definitions = cleanup_packed_string(newFlags.definitions)
	newFlags.examples = cleanup_packed_string(newFlags.examples)
	newFlags.audioUrls = cleanup_packed_string(newFlags.audioUrls)
	newFlags.deconstruct_phonetics()
	return newFlags

static func cleanup_packed_string(inPacked : PackedStringArray) -> PackedStringArray:
	var outUnique : PackedStringArray = PackedStringArray([""])
	for eachString in inPacked:
		if !outUnique.has(eachString):
			outUnique.append(eachString)
	outUnique.erase("")
	return outUnique

func overlapping_words(inDict : Dictionary):
	for defKeys in inDict.keys():
		match defKeys:
			"phonetic":
				phonetics.append(inDict["phonetic"])
			"phonetics":
				for eachPhonetic in inDict["phonetics"]:
					for phoneticKeys in eachPhonetic.keys():
						match phoneticKeys:
							"text":
								phonetics.append(eachPhonetic[phoneticKeys])
							"audio":
								audioUrls.append(eachPhonetic[phoneticKeys])
			"meanings":
				for eachMeaning in inDict["meanings"]:
					partsOfSpeech.append(eachMeaning["partOfSpeech"])
					synonyms.append_array(eachMeaning["synonyms"])
					antonyms.append_array(eachMeaning["antonyms"])
					for eachDefinition in eachMeaning["definitions"]:
						definitions.append(eachDefinition["definition"])
						if eachDefinition.keys().has("example"):
							examples.append(eachDefinition["example"])

func deconstruct_phonetics():
	#Each Phonetic Pronounciation
	for eachPhonetic in phonetics:
		var newDict : Dictionary = Phonetics.phonetic_breakdown(eachPhonetic)
		deconstructedPhonetics.append(newDict)

func get_phonetics() -> Array:
	var outPhonetics : Array = []
	for eachDecon in deconstructedPhonetics:
		for eachFlag in eachDecon["Flags"]:
			outPhonetics.append(eachFlag)
	return outPhonetics

func get_synonyms() -> PackedStringArray:
	return synonyms

func get_antonyms() -> PackedStringArray:
	return antonyms

func get_parts_of_speech() -> PackedStringArray:
	return partsOfSpeech

func json_save() -> Dictionary:
	var saveOutput : Dictionary = {
		"word" : word,
		"phonetics" : phonetics,
		"synonyms" : synonyms,
		"antonyms" : antonyms,
		"partsOfSpeech" : partsOfSpeech,
		"definitions" : definitions,
		"examples" : examples,
		"audioUrls" : audioUrls
	}
	return saveOutput

static func json_load(inDict) -> NameFlags:
	var newFlags = NameFlags.new()
	newFlags.word = inDict["word"]
	newFlags.phonetics = inDict["phonetics"]
	newFlags.synonyms = inDict["synonyms"]
	newFlags.antonyms = inDict["antonyms"]
	newFlags.partsOfSpeech = inDict["partsOfSpeech"]
	newFlags.definitions = inDict["definitions"]
	newFlags.examples = inDict["examples"]
	newFlags.audioUrls = inDict["audioUrls"]
	newFlags.deconstruct_phonetics()
	return newFlags

func get_flag_type():
	return FlagType.NAME_FLAG

func get_score(baseColor : ColorCatagory) -> float:
	##The score these name flag's give
	var score : float = 0
	#The name of the card's the most important part
	score += baseColor.get_word_score(word) * baseColor.MULTI_CARD_NAME
	#Just get the most value you can from the synonyms
	var bestSynonymScore : float = 0
	for syn in synonyms:
		var eachScore = baseColor.get_word_score(syn) * baseColor.MULTI_SYNONYMS
		bestSynonymScore = max(bestSynonymScore, eachScore)
	score += bestSynonymScore
	#Likewise for the anyonyms
	var bestAntonymScore : float = 0
	for ant in antonyms:
		var eachScore = baseColor.get_word_score(ant) * baseColor.MULTI_ANTONYMS
		bestAntonymScore = min(bestAntonymScore, eachScore)
	score += bestAntonymScore
	for parts in partsOfSpeech:
		#Lookup Parts
		if baseColor.lookupTagsParts.has(parts):
			score += baseColor.lookupTagsParts[parts] / partsOfSpeech.size()
	for defs in definitions:
		score += baseColor.get_words_score(defs.to_lower()) * baseColor.MULTI_DEFINITION / definitions.size()
	for eggs in examples:
		score += baseColor.get_words_score(eggs.to_lower()) * baseColor.MULTI_EXAMPLE / examples.size()
	#Phonetics
	for eachDecon in deconstructedPhonetics:
		for phonFlags in eachDecon["Flags"]:
			score += baseColor.get_phonetic_score(phonFlags) * baseColor.MULTI_PHONETIC / deconstructedPhonetics.size()
	return score
