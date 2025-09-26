extends Resource
class_name ColorCatagory

##The base colors that Arcardelago has
static var BASE_COLORS : Array[ColorCatagory] = [
	load("res://Resources/ColorCatagories/RedColorCat.tres") as ColorCatagory,
	load("res://Resources/ColorCatagories/GreenColorCat.tres") as ColorCatagory,
	load("res://Resources/ColorCatagories/VioletColorCat.tres") as ColorCatagory,
	load("res://Resources/ColorCatagories/OrangeColorCat.tres") as ColorCatagory,
	load("res://Resources/ColorCatagories/BlueColorCat.tres") as ColorCatagory,
	load("res://Resources/ColorCatagories/YellowColorCat.tres") as ColorCatagory
]
##The enum respresentaiton of the color catagory
enum ColorTypes {
	RED, ##Traps & Risk 
	GREEN, ##Locations, Enemies & Low Card Count
	VIOLET, ##Yourself & Progressive Items
	ORANGE, ##Proguseful & Power
	BLUE, ##Filler, Useful & High Card Count
	YELLOW, ##Other Players & Item Sending
	CUSTOM ##A color made by others
}
const RED = ColorTypes.RED
const GREEN = ColorTypes.GREEN
const VIOLET = ColorTypes.VIOLET
const ORANGE = ColorTypes.ORANGE
const BLUE = ColorTypes.BLUE
const YELLOW = ColorTypes.YELLOW
enum SourcePref {NULL, LOCAL, EXTERNAL}
@export var name : String
@export var colorType : ColorTypes
@export_color_no_alpha var color : Color
@export_multiline var description : String

#Internal Catagory Multiplier Constants
const MULTI_COLOR = 10 ##100 if Card Name, 50 Synonym, -50 Antonym
const MULTI_NAMES = 5 ##50 if Card Name, 25 Synonym, -25 Antonym
const MULTI_PHONETIC = 1 ##Phonetics are high in count
#External Score Multipliers
const MULTI_SOURCE = 25 ##Local/Non Local
const MULTI_ITEM_FLAGS = 25 ##Filler/Useful/Trap/Progression/Proguseful
const MULTI_CARD_NAME = 10 ##100 if Color and 50 if Typing
const MULTI_SYNONYMS = 5 ##50 if Color and 25 if Typing
const MULTI_ANTONYMS = -5 ##-50 if Color and -25 if Typing
const MULTI_DEFINITION = 1 ##10 if Color and 5 if Typing
const MULTI_EXAMPLE = 1 ##1 if Color and 5 if Typing
#Phonetic Score Applications
const PHSCR_NAME = 2
const PHSCR_TYPE = 5
const PHSCR_DIACRITIC = 10
const PHSCR_VOWEL_ROUNDED = 1
const PHSCR_CON_SOUND = 1
const PHSCR_CON_SHAPE = 1
const PHSCR_CON_VOICE = 1
const MULTI_PHSCR_VOWEL_GOAL = .25
const MAX_VOWL_DIST = 2 * sqrt(2)
const MULTI_PHSCR_TONE_GOAL = 5

@export_group("Word Tags", "lookupTags")
##Words that are similar colors give a x10 point multi
@export var lookupTagsColor : Array[WordWeight]
##Arbitrary Word Flags give a x5 point multi
@export var lookupTagsArbitraryWordGroups : Array[ArbitraryWordGroups]
##Parts of Speech are worth fixed points
@export var lookupTagsParts : Dictionary[String, float]
@export_group("Phonetic Tags", "phon")
##The name of the exact phonetic you want
@export var phonName : PackedStringArray
##If you're of the given type give 5 score
@export var phonTypes : Array[Phonetics.PhoneticType]
##Matching Diacritical Commands gives 10 points
@export var phonDiacriticCommand : PackedStringArray
##Vowels give up to 2 points based on distance to vowel goals
@export var phonVowelGoal : PackedVector2Array
##Get 1 point for matching the wanted roundness
@export var phonVowelRoundPref : Array[bool]
##Consonants of the given sound gives 1 point
@export var phonConsonantSound : Array[Phonetics.PulCon.Sound]
##Consonants of the given shape gives 1 point
@export var phonConsonantShape : Array[Phonetics.Consonant.Shape]
##Matching the voiced goal gives 1 point
@export var phonConsonantVoiced : Array[Phonetics.Consonant.Voiced]
##Matching the tone gives 5 points
@export var phonToneGoal : PackedFloat32Array

@export_group("AP Data", "item")
@export var itemQualityMulti = 1
@export_flags("Progression", "Useful", "Trap") var itemQualityFlags : PackedInt32Array
@export var itemSourcePref : SourcePref

static func get_color(inColorType : ColorTypes) -> Color:
	match inColorType:
		RED:
			return Color.RED
		GREEN:
			return Color.GREEN
		VIOLET:
			return Color.VIOLET
		ORANGE:
			return Color.ORANGE
		BLUE:
			return Color.BLUE
		YELLOW:
			return Color.YELLOW
		_:
			return Color.BLACK

##Compares the word directly
func get_word_score(word : String) -> float:
	var score : float = 0.0
	#Words that include colors score high
	for colTags in lookupTagsColor:
		if colTags.word.to_lower() == word.to_lower():
			score += colTags.weight * MULTI_COLOR
	#Words that include similar tags
	for awg in lookupTagsArbitraryWordGroups:
		score += awg.color_score(name, word)
	#Output the Score
	return score

##Looks for counts of this word showing up
func get_words_score(words : String):
	var score : float = 0.0
	#Words that include colors score high
	for colTags in lookupTagsColor:
		if words.containsn(colTags.word):
			score += colTags.weight * MULTI_COLOR
	#Words that include similar tags
	for awg in lookupTagsArbitraryWordGroups:
		score += awg.color_score(name, words, true)
	#Output the Score
	return score

##Phonetic score calculation
func get_phonetic_score(phonetic : Phonetics.PhoneticFlag) -> float:
	var score : float = 0
	#Phonetic Directly Matches
	if phonName.has(phonetic.name):
		score += PHSCR_NAME
	#Phonetic Type Matches
	if phonTypes.has(phonetic.type):
		score += PHSCR_TYPE
	#Phonetic Flags
	match phonetic.type:
		#Consonants
		Phonetics.PhoneticType.COARTICULATED_CONSONANT:
			if phonConsonantShape.has(phonetic.shp2):
				score += PHSCR_CON_SHAPE
			if phonConsonantShape.has(phonetic.shp):
				score += PHSCR_CON_SHAPE
			if phonConsonantSound.has(phonetic.snd):
				score += PHSCR_CON_SOUND
			if phonConsonantVoiced.has(phonetic.voiced):
				score += PHSCR_CON_VOICE
		Phonetics.PhoneticType.PULMONIC_CONSONANT:
			if phonConsonantShape.has(phonetic.shp):
				score += PHSCR_CON_SHAPE
			if phonConsonantSound.has(phonetic.snd):
				score += PHSCR_CON_SOUND
			if phonConsonantVoiced.has(phonetic.voiced):
				score += PHSCR_CON_VOICE
		Phonetics.PhoneticType.CLICK:
			if phonConsonantShape.has(phonetic.shp):
				score += PHSCR_CON_SHAPE
			if phonConsonantVoiced.has(phonetic.voiced):
				score += PHSCR_CON_VOICE
		Phonetics.PhoneticType.VOICED_IMPLOSIVE:
			if phonConsonantShape.has(phonetic.shp):
				score += PHSCR_CON_SHAPE
			if phonConsonantVoiced.has(phonetic.voiced):
				score += PHSCR_CON_VOICE
		Phonetics.PhoneticType.EJECTIVE:
			if phonConsonantShape.has(phonetic.shp):
				score += PHSCR_CON_SHAPE
			if phonConsonantVoiced.has(phonetic.voiced):
				score += PHSCR_CON_VOICE
		#Vowels
		Phonetics.PhoneticType.VOWEL:
			var bestGoal : float = 0.0
			#Pick the best score from all distances to vowels, ranged (-1,-1 to +1,+1)
			for eachCoord in phonVowelGoal:
				bestGoal = maxf(bestGoal, MAX_VOWL_DIST - eachCoord.distance_to(phonetic.pos))
			#Apply it to the score
			score += bestGoal * MULTI_PHSCR_VOWEL_GOAL
			if phonVowelRoundPref.has(phonetic.rounded):
				score += PHSCR_VOWEL_ROUNDED
		Phonetics.PhoneticType.R_COLORED_VOWEL:
			var bestGoal : float = 0.0
			#Pick the best score from all distances to vowels, ranged (-1,-1 to +1,+1)
			for eachCoord in phonVowelGoal:
				bestGoal = maxf(bestGoal, MAX_VOWL_DIST - eachCoord.distance_to(phonetic.pos))
			#Apply it to the score
			score += bestGoal * MULTI_PHSCR_VOWEL_GOAL
			if phonVowelRoundPref.has(phonetic.rounded):
				score += PHSCR_VOWEL_ROUNDED
		#Diacritic Command
		Phonetics.PhoneticType.DIACRITIC:
			if phonDiacriticCommand.has(phonetic.command):
				score += PHSCR_DIACRITIC
		#Tone Value
		Phonetics.PhoneticType.TONE:
			var bestGoal : float = 0.0
			#Pick the best score from distance from all tones, ranged (-1 to +1)
			for eachTone in phonToneGoal:
				bestGoal = maxf(bestGoal, abs(phonetic.tone - eachTone) - 2)
			#Apply it to the score
			score += bestGoal * MULTI_PHSCR_TONE_GOAL
	return score
