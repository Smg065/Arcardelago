extends NameFlagBase
class_name NameFlags

var phonetics : PackedStringArray
var richPhonetics : PackedStringArray
var deconstructedPhonetics : Array
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
		var richText : String = ""
		match newDict["Transcription"]:
			Phonetics.Transcription.PHONEMIC:
				richText += "[bgcolor=SLATE_GRAY]"
			Phonetics.Transcription.PHONETIC:
				richText += "[bgcolor=MIDNIGHT_BLUE]"
			Phonetics.Transcription.UNKNOWN:
				richText += "[bgcolor=MAGENTA]"
		for eachChar in newDict["Flags"]:
			richText += eachChar.rich_text()
		richText += "[/bgcolor]"
		richPhonetics.append(richText)

func rich_text_name(inStr : String = word.capitalize().replace(" ", "")) -> String:
	var hintText : String = "\n".join(definitions).replace("[", "[lb]").replace("]", "[rb]").replace(String.chr(34), "''")
	hintText = String.chr(34) + hintText + String.chr(34)
	return "[hint=%s]%s[/hint]" % [hintText, inStr]

func rich_text_phonetics() -> String:
	if richPhonetics.size() == 0:
		return "[hint=%s][bgcolor=BLACK][color=WHITE]N/A[/color][/bgcolor][/hint]" % word
	return "/".join(richPhonetics)

func get_synonyms() -> PackedStringArray:
	return synonyms

func get_antonyms() -> PackedStringArray:
	return antonyms

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
