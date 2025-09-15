class_name NameFlags

var word : String
var phonetics : PackedStringArray
var synonyms : PackedStringArray
var antonyms : PackedStringArray
var partsOfSpeech : PackedStringArray
var definitions : PackedStringArray
var examples : PackedStringArray
var audioUrls : PackedStringArray

func _init(jsonData : Array):
	word = jsonData[0]["word"]
	for eachEntry in jsonData:
		overlapping_words(eachEntry)
	#Cleanup Packed String Arrays
	phonetics = cleanup_packed_string(phonetics)
	for eachEntry in phonetics.size():
		phonetics[eachEntry] = phonetics[eachEntry].trim_prefix("/").trim_suffix("/")
	synonyms = cleanup_packed_string(synonyms)
	antonyms = cleanup_packed_string(antonyms)
	partsOfSpeech = cleanup_packed_string(partsOfSpeech)
	definitions = cleanup_packed_string(definitions)
	examples = cleanup_packed_string(examples)
	audioUrls = cleanup_packed_string(audioUrls)

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
