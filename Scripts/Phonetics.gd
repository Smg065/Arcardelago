class_name Phonetics

class PulCon:
	extends Consonant
	enum Sound {PLOSIVE, NASAL, TRILL, TAP_FLAP, LATERAL_TAP_FLAP, FRICATIVE, FRICATIVE_SIBILANT, APPROXIMANT, LATERAL_FRICATIVE, LATERAL_APPROXIMANT}
	var snd : Sound
	
	func _init(nName, nShp, nSnd, nVoiced) -> void:
		name = nName
		shp = nShp
		snd = nSnd
		voiced = nVoiced
		type = PhoneticType.PULMONIC_CONSONANT
	
	func hint_text():
		var outText : String = "\nShape: %s" % Shape.keys()[shp].capitalize()
		outText += "\nSound: %s" % Sound.keys()[snd].capitalize()
		if voiced != Voiced.NULL:
			outText += "\n%s" % Voiced.keys()[voiced].capitalize()
		return outText
	
	static func plbuild(nName, nShp, nSnd, nVoiced) -> PulCon:
		return PulCon.new(nName, nShp, nSnd, nVoiced)

class CoCon:
	extends PulCon
	var shp2 : Shape
	
	func _init(nName, nShp, nShp2, nSnd, nVoiced) -> void:
		name = nName
		shp = nShp
		shp2 = nShp2
		snd = nSnd
		voiced = nVoiced
		type = PhoneticType.COARTICULATED_CONSONANT
	
	func hint_text():
		var outText : String = "\nShape 1: %s" % Shape.keys()[shp].capitalize()
		outText += "\nShape 2: %s" % Shape.keys()[shp2].capitalize()
		outText += "\nSound: %s" % Sound.keys()[snd].capitalize()
		if voiced != Voiced.NULL:
			outText += "\n%s" % Voiced.keys()[voiced].capitalize()
		return outText
	
	static func cobuild(nName, nShp, nShp2, nSnd, nVoiced) -> CoCon:
		return new(nName, nShp, nShp2, nSnd, nVoiced)

class Consonant:
	extends PhoneticFlag
	enum Shape {BILABIAL, LABIODENTAL, LINGUOLABIAL, DENTAL, ALVEOLAR, POSTALVEOLAR, RETROFLEX, PALATAL, VELAR, UVULAR, PHARYNGEAL_EPIGOLOTTAL, GLOTTAL, LATERAL, LABIAL, NULL}
	enum Voiced {NULL, UNVOICED, VOICED}
	var shp : Shape
	var voiced : Voiced
	
	func _init(nName, nShp, nVoiced, nType) -> void:
		name = nName
		shp = nShp
		voiced = nVoiced
		type = nType
	
	func hint_text():
		var outText : String = "\nShape: %s" % Shape.keys()[shp].capitalize()
		if voiced != Voiced.NULL:
			outText += "\n%s" % Voiced.keys()[voiced].capitalize()
		return outText
	
	static func cnsbuild(nName, nShp, nVoiced, nType) -> Consonant:
		return Consonant.new(nName, nShp, nVoiced, nType)

class RColored:
	extends Vowel
	func _init(nName, nPos, nRounded):
		name = nName
		pos = nPos
		rounded = nRounded
		type = PhoneticType.R_COLORED_VOWEL
	static func rvbuild(nName, nPos, nRounded) -> RColored:
		return RColored.new(nName, nPos, nRounded)

class Vowel:
	extends PhoneticFlag
	var pos : Vector2
	var rounded : bool
	
	func _init(nName, nPos, nRounded):
		name = nName
		pos = nPos
		rounded = nRounded
		type = PhoneticType.VOWEL
	
	func hint_text():
		var outText : String = "\nPos: %1.1v" % pos
		if rounded:
			outText += "\nRounded"
		return outText
	
	static func vlbuild(nName, nPos, nRounded) -> Vowel:
		return Vowel.new(nName, nPos, nRounded)

class Tone:
	extends PhoneticFlag
	var tone : float
	
	func _init(nName, nTone):
		name = nName
		tone = nTone
		type = PhoneticType.TONE
	
	func hint_text():
		return "\nTone : %1.1f" % tone
	
	static func tnbuild(nName, nTone) -> Tone:
		return Tone.new(nName, nTone)

class Diacritic:
	extends PhoneticFlag
	var command : String
	
	func _init(newName, nCommand) -> void:
		name = newName
		command = nCommand
		type = PhoneticType.DIACRITIC
	
	static func dcbuild(newName : String, nCommand : String) -> Diacritic:
		return Diacritic.new(newName, nCommand)
	
	func is_next(inString : String):
		return inString.begins_with(name)
	
	func hint_text():
		return "\nCommand: " + command

class PhoneticFlag:
	var name : String
	var type : Phonetics.PhoneticType
	
	func _init(newName, newType) -> void:
		name = newName
		type = newType
	
	static func build(newName : String, newType : Phonetics.PhoneticType) -> PhoneticFlag:
		return PhoneticFlag.new(newName, newType)
	
	func is_next(inString : String):
		return inString.begins_with(name)
	
	func hint_text():
		return ""
	
	func rich_text(count : int = 1) -> String:
		var hintText : String = ""
		var color : String = "BLACK"
		match type:
			PhoneticType.PULMONIC_CONSONANT:
				color = "SNOW"
				hintText = hint_text()
			PhoneticType.VOWEL:
				color = "GRAY"
				hintText = hint_text()
			PhoneticType.R_COLORED_VOWEL:
				color = "PINK"
				hintText = hint_text()
			PhoneticType.CLICK:
				color = "OLIVE"
			PhoneticType.VOICED_IMPLOSIVE:
				color = "WEB_GREEN"
			PhoneticType.EJECTIVE:
				color = "DODGER_BLUE"
			PhoneticType.COARTICULATED_CONSONANT:
				color = "REBECCA_PURPLE"
				hintText = hint_text()
			PhoneticType.PRIMARY_STRESS:
				color = "ORANGE"
			PhoneticType.SECONDARY_STRESS:
				color = "CHOCOLATE"
			PhoneticType.LONG:
				color = "DARK_GREEN"
			PhoneticType.HALF_LONG:
				color = "DARK_GREEN"
			PhoneticType.EXTRA_SHORT:
				color = "DARK_GREEN"
			PhoneticType.SYLLABLE_BREAK:
				color = "DARK_GREEN"
			PhoneticType.MINOR_GROUP:
				color = "PLUM"
			PhoneticType.MAJOR_GROUP:
				color = "DARK_ORCHID"
			PhoneticType.LINKING:
				color = "DIM_GRAY"
			PhoneticType.TONE:
				color = "PALE_GREEN"
				hintText = hint_text()
			PhoneticType.UPSTEP:
				color = "MEDIUM_SEA_GREEN"
			PhoneticType.DOWNSTEP:
				color = "SEA_GREEN"
			PhoneticType.BRACKET_START:
				color = "BLACK"
			PhoneticType.BRACKET_END:
				color = "BLACK"
			PhoneticType.DIACRITIC:
				hintText = hint_text()
				color = "PURPLE"
			PhoneticType.MISC:
				color = "BLACK"
			PhoneticType.UNKNOWN:
				print(name)
				color = "MAGENTA"
		var appliedText : String = name
		appliedText += "x" + str(count)
		return "[color=%s][hint=\"%s\"]%s[/hint][/color]" % [color, PhoneticType.keys()[type].capitalize() + hintText, appliedText]

#/Phonemic/, [Phonetic]
enum Transcription {PHONEMIC, PHONETIC, UNKNOWN}

enum PhoneticType {PULMONIC_CONSONANT, VOWEL, R_COLORED_VOWEL, CLICK, 
VOICED_IMPLOSIVE, EJECTIVE, COARTICULATED_CONSONANT, PRIMARY_STRESS, 
SECONDARY_STRESS, LONG, HALF_LONG, EXTRA_SHORT, SYLLABLE_BREAK, MINOR_GROUP, 
MAJOR_GROUP, LINKING, TONE, UPSTEP, DOWNSTEP, BRACKET_START, BRACKET_END, 
DIACRITIC, MISC, UNKNOWN}

static var LOOKUP = [
	#Pulmonic Consonants
	PulCon.plbuild("p", PulCon.Shape.BILABIAL, PulCon.Sound.PLOSIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("b", PulCon.Shape.BILABIAL, PulCon.Sound.PLOSIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("m", PulCon.Shape.BILABIAL, PulCon.Sound.NASAL, PulCon.Voiced.NULL),
	PulCon.plbuild("ʙ", PulCon.Shape.BILABIAL, PulCon.Sound.TRILL, PulCon.Voiced.NULL),
	PulCon.plbuild("ⱱ̟", PulCon.Shape.BILABIAL, PulCon.Sound.TAP_FLAP, PulCon.Voiced.NULL),
	PulCon.plbuild("ɸ", PulCon.Shape.BILABIAL, PulCon.Sound.FRICATIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("β", PulCon.Shape.BILABIAL, PulCon.Sound.FRICATIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("β̞", PulCon.Shape.BILABIAL, PulCon.Sound.APPROXIMANT, PulCon.Voiced.NULL),
	PulCon.plbuild("p̪", PulCon.Shape.LABIODENTAL, PulCon.Sound.PLOSIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("b̪", PulCon.Shape.LABIODENTAL, PulCon.Sound.PLOSIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("ɱ", PulCon.Shape.LABIODENTAL, PulCon.Sound.NASAL, PulCon.Voiced.NULL),
	PulCon.plbuild("ⱱ", PulCon.Shape.LABIODENTAL, PulCon.Sound.TAP_FLAP, PulCon.Voiced.NULL),
	PulCon.plbuild("f", PulCon.Shape.LABIODENTAL, PulCon.Sound.FRICATIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("v", PulCon.Shape.LABIODENTAL, PulCon.Sound.FRICATIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("ʋ", PulCon.Shape.LABIODENTAL, PulCon.Sound.APPROXIMANT, PulCon.Voiced.NULL),
	PulCon.plbuild("t̼", PulCon.Shape.LINGUOLABIAL, PulCon.Sound.PLOSIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("d̼", PulCon.Shape.LINGUOLABIAL, PulCon.Sound.PLOSIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("n̼", PulCon.Shape.LINGUOLABIAL, PulCon.Sound.NASAL, PulCon.Voiced.NULL),
	PulCon.plbuild("r̼", PulCon.Shape.LINGUOLABIAL, PulCon.Sound.TRILL, PulCon.Voiced.NULL),
	PulCon.plbuild("ɾ̼", PulCon.Shape.LINGUOLABIAL, PulCon.Sound.TAP_FLAP, PulCon.Voiced.NULL),
	PulCon.plbuild("θ̼", PulCon.Shape.LINGUOLABIAL, PulCon.Sound.FRICATIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("ð̼", PulCon.Shape.LINGUOLABIAL, PulCon.Sound.FRICATIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("l̼", PulCon.Shape.LINGUOLABIAL, PulCon.Sound.LATERAL_APPROXIMANT, PulCon.Voiced.NULL),
	PulCon.plbuild("t̪", PulCon.Shape.DENTAL, PulCon.Sound.PLOSIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("d̪", PulCon.Shape.DENTAL, PulCon.Sound.PLOSIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("n̪", PulCon.Shape.DENTAL, PulCon.Sound.NASAL, PulCon.Voiced.NULL),
	PulCon.plbuild("r̪", PulCon.Shape.DENTAL, PulCon.Sound.TRILL, PulCon.Voiced.NULL),
	PulCon.plbuild("ɾ̪", PulCon.Shape.DENTAL, PulCon.Sound.TAP_FLAP, PulCon.Voiced.NULL),
	PulCon.plbuild("θ", PulCon.Shape.DENTAL, PulCon.Sound.FRICATIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("ð", PulCon.Shape.DENTAL, PulCon.Sound.FRICATIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("s̪", PulCon.Shape.DENTAL, PulCon.Sound.FRICATIVE_SIBILANT, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("z̪", PulCon.Shape.DENTAL, PulCon.Sound.FRICATIVE_SIBILANT, PulCon.Voiced.VOICED),
	PulCon.plbuild("ð̞", PulCon.Shape.DENTAL, PulCon.Sound.APPROXIMANT, PulCon.Voiced.NULL),
	PulCon.plbuild("ɬ̪", PulCon.Shape.DENTAL, PulCon.Sound.LATERAL_FRICATIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("ɮ̪", PulCon.Shape.DENTAL, PulCon.Sound.LATERAL_FRICATIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("l̪", PulCon.Shape.DENTAL, PulCon.Sound.LATERAL_APPROXIMANT, PulCon.Voiced.NULL),
	PulCon.plbuild("t", PulCon.Shape.ALVEOLAR, PulCon.Sound.PLOSIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("d", PulCon.Shape.ALVEOLAR, PulCon.Sound.PLOSIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("n", PulCon.Shape.ALVEOLAR, PulCon.Sound.NASAL, PulCon.Voiced.NULL),
	PulCon.plbuild("r", PulCon.Shape.ALVEOLAR, PulCon.Sound.TRILL, PulCon.Voiced.NULL),
	PulCon.plbuild("ɾ", PulCon.Shape.ALVEOLAR, PulCon.Sound.TAP_FLAP, PulCon.Voiced.NULL),
	PulCon.plbuild("ɺ", PulCon.Shape.ALVEOLAR, PulCon.Sound.LATERAL_TAP_FLAP, PulCon.Voiced.NULL),
	PulCon.plbuild("s", PulCon.Shape.ALVEOLAR, PulCon.Sound.FRICATIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("z", PulCon.Shape.ALVEOLAR, PulCon.Sound.FRICATIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("ɹ", PulCon.Shape.ALVEOLAR, PulCon.Sound.APPROXIMANT, PulCon.Voiced.NULL),
	PulCon.plbuild("ɬ", PulCon.Shape.ALVEOLAR, PulCon.Sound.LATERAL_FRICATIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("ɮ", PulCon.Shape.ALVEOLAR, PulCon.Sound.LATERAL_FRICATIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("l", PulCon.Shape.ALVEOLAR, PulCon.Sound.LATERAL_APPROXIMANT, PulCon.Voiced.NULL),
	PulCon.plbuild("ʃ", PulCon.Shape.POSTALVEOLAR, PulCon.Sound.FRICATIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("ʒ", PulCon.Shape.POSTALVEOLAR, PulCon.Sound.FRICATIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("ʈ", PulCon.Shape.RETROFLEX, PulCon.Sound.PLOSIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("ɖ", PulCon.Shape.RETROFLEX, PulCon.Sound.PLOSIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("ɳ", PulCon.Shape.RETROFLEX, PulCon.Sound.NASAL, PulCon.Voiced.NULL),
	PulCon.plbuild("ɽ", PulCon.Shape.RETROFLEX, PulCon.Sound.TAP_FLAP, PulCon.Voiced.NULL),
	PulCon.plbuild("𝼈", PulCon.Shape.RETROFLEX, PulCon.Sound.LATERAL_TAP_FLAP, PulCon.Voiced.NULL),
	PulCon.plbuild("ʂ", PulCon.Shape.RETROFLEX, PulCon.Sound.FRICATIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("ʐ", PulCon.Shape.RETROFLEX, PulCon.Sound.FRICATIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("ɻ", PulCon.Shape.RETROFLEX, PulCon.Sound.APPROXIMANT, PulCon.Voiced.NULL),
	PulCon.plbuild("ꞎ", PulCon.Shape.RETROFLEX, PulCon.Sound.LATERAL_FRICATIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("𝼅", PulCon.Shape.RETROFLEX, PulCon.Sound.LATERAL_FRICATIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("ɭ", PulCon.Shape.RETROFLEX, PulCon.Sound.LATERAL_APPROXIMANT, PulCon.Voiced.NULL),
	PulCon.plbuild("c", PulCon.Shape.PALATAL, PulCon.Sound.PLOSIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("ɟ", PulCon.Shape.PALATAL, PulCon.Sound.PLOSIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("ɲ", PulCon.Shape.PALATAL, PulCon.Sound.NASAL, PulCon.Voiced.NULL),
	PulCon.plbuild("ʎ̮", PulCon.Shape.PALATAL, PulCon.Sound.LATERAL_TAP_FLAP, PulCon.Voiced.NULL),
	PulCon.plbuild("ç", PulCon.Shape.PALATAL, PulCon.Sound.FRICATIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("ʝ", PulCon.Shape.PALATAL, PulCon.Sound.FRICATIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("j", PulCon.Shape.PALATAL, PulCon.Sound.APPROXIMANT, PulCon.Voiced.NULL),
	PulCon.plbuild("𝼆", PulCon.Shape.PALATAL, PulCon.Sound.LATERAL_FRICATIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("ʎ̝", PulCon.Shape.PALATAL, PulCon.Sound.LATERAL_FRICATIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("𝼆̬", PulCon.Shape.PALATAL, PulCon.Sound.LATERAL_FRICATIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("ʎ", PulCon.Shape.PALATAL, PulCon.Sound.LATERAL_APPROXIMANT, PulCon.Voiced.NULL),
	PulCon.plbuild("k", PulCon.Shape.VELAR, PulCon.Sound.PLOSIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("ɡ", PulCon.Shape.VELAR, PulCon.Sound.PLOSIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("ŋ", PulCon.Shape.VELAR, PulCon.Sound.NASAL, PulCon.Voiced.NULL),
	PulCon.plbuild("ʟ̆", PulCon.Shape.VELAR, PulCon.Sound.LATERAL_TAP_FLAP, PulCon.Voiced.NULL),
	PulCon.plbuild("x", PulCon.Shape.VELAR, PulCon.Sound.FRICATIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("ɣ", PulCon.Shape.VELAR, PulCon.Sound.FRICATIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("ɰ", PulCon.Shape.VELAR, PulCon.Sound.APPROXIMANT, PulCon.Voiced.NULL),
	PulCon.plbuild("𝼄", PulCon.Shape.VELAR, PulCon.Sound.LATERAL_FRICATIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("ʟ̝", PulCon.Shape.VELAR, PulCon.Sound.LATERAL_FRICATIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("𝼄̬", PulCon.Shape.VELAR, PulCon.Sound.LATERAL_FRICATIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("ʟ", PulCon.Shape.VELAR, PulCon.Sound.LATERAL_APPROXIMANT, PulCon.Voiced.NULL),
	PulCon.plbuild("q", PulCon.Shape.UVULAR, PulCon.Sound.PLOSIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("ɢ", PulCon.Shape.UVULAR, PulCon.Sound.PLOSIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("ɴ", PulCon.Shape.UVULAR, PulCon.Sound.NASAL, PulCon.Voiced.NULL),
	PulCon.plbuild("ʀ", PulCon.Shape.UVULAR, PulCon.Sound.TRILL, PulCon.Voiced.NULL),
	PulCon.plbuild("ɢ̆", PulCon.Shape.UVULAR, PulCon.Sound.TAP_FLAP, PulCon.Voiced.NULL),
	PulCon.plbuild("χ", PulCon.Shape.UVULAR, PulCon.Sound.FRICATIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("ʁ", PulCon.Shape.UVULAR, PulCon.Sound.FRICATIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("ʡ", PulCon.Shape.PHARYNGEAL_EPIGOLOTTAL, PulCon.Sound.PLOSIVE, PulCon.Voiced.NULL),
	PulCon.plbuild("ʜ", PulCon.Shape.PHARYNGEAL_EPIGOLOTTAL, PulCon.Sound.TRILL, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("ʢ", PulCon.Shape.PHARYNGEAL_EPIGOLOTTAL, PulCon.Sound.TRILL, PulCon.Voiced.VOICED),
	PulCon.plbuild("ħ", PulCon.Shape.PHARYNGEAL_EPIGOLOTTAL, PulCon.Sound.FRICATIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("ʕ", PulCon.Shape.PHARYNGEAL_EPIGOLOTTAL, PulCon.Sound.FRICATIVE, PulCon.Voiced.VOICED),
	PulCon.plbuild("ʔ", PulCon.Shape.GLOTTAL, PulCon.Sound.PLOSIVE, PulCon.Voiced.NULL),
	PulCon.plbuild("h", PulCon.Shape.GLOTTAL, PulCon.Sound.FRICATIVE, PulCon.Voiced.UNVOICED),
	PulCon.plbuild("ɦ", PulCon.Shape.GLOTTAL, PulCon.Sound.FRICATIVE, PulCon.Voiced.VOICED),
	#Vowel
	Vowel.vlbuild("i", Vector2(1, 1), false),
	Vowel.vlbuild("y", Vector2(1, 1), true),
	Vowel.vlbuild("ɨ", Vector2(0, 1), false),
	Vowel.vlbuild("ʉ", Vector2(0, 1), true),
	Vowel.vlbuild("ɯ", Vector2(-1, 1), false),
	Vowel.vlbuild("u", Vector2(-1, 1), true),
	Vowel.vlbuild("ɪ", Vector2(.35, 0.666666667), false),
	Vowel.vlbuild("ʏ", Vector2(.35, 0.666666667), true),
	Vowel.vlbuild("ʊ", Vector2(-.5, 0.666666667), false),
	Vowel.vlbuild("e", Vector2(.65, 0.333333333), false),
	Vowel.vlbuild("ø", Vector2(.65, 0.333333333), true),
	Vowel.vlbuild("ɘ", Vector2(-.2, 0.333333333), false),
	Vowel.vlbuild("ɵ", Vector2(-.2, 0.333333333), true),
	Vowel.vlbuild("ɤ", Vector2(-1, 0.333333333), false),
	Vowel.vlbuild("o", Vector2(-1, 0.333333333), true),
	Vowel.vlbuild("ə", Vector2(-.25, 0), false),
	Vowel.vlbuild("ɛ", Vector2(.3, -0.333333333), false),
	Vowel.vlbuild("œ", Vector2(.3, -0.333333333), true),
	Vowel.vlbuild("ɜ", Vector2(-.3, -0.333333333), false),
	Vowel.vlbuild("ɞ", Vector2(-.3, -0.333333333), true),
	Vowel.vlbuild("ʌ", Vector2(-1, -0.333333333), false),
	Vowel.vlbuild("ɔ", Vector2(-1, -0.333333333), true),
	Vowel.vlbuild("æ", Vector2(.333333333, -0.666666667), false),
	Vowel.vlbuild("ɐ", Vector2(-.4, -0.666666667), false),
	Vowel.vlbuild("a", Vector2(-0.1, -1), false),
	Vowel.vlbuild("ɶ", Vector2(-0.1, -1), true),
	Vowel.vlbuild("ɑ", Vector2(-1, -1), false),
	Vowel.vlbuild("ɒ", Vector2(-1, -1), true),
	#Uncharted
	PulCon.plbuild("ɫ", PulCon.Shape.VELAR, PulCon.Sound.LATERAL_APPROXIMANT, PulCon.Voiced.NULL),
	Vowel.vlbuild("ä", Vector2(0, -1), false),
	#R Colored Vowels
	RColored.rvbuild("ɚ", Vector2(-.25, 0), false),
	RColored.rvbuild("ɝ", Vector2(-.3, -0.333333333), false),
	RColored.rvbuild("ɹ̩", Vector2.ZERO, true),
	RColored.rvbuild("ɻ̍", Vector2.ZERO, true),
	#Clicks
	Consonant.cnsbuild("ʘ", PulCon.Shape.BILABIAL, PulCon.Voiced.NULL, PhoneticType.CLICK),
	Consonant.cnsbuild("ǀ", PulCon.Shape.DENTAL, PulCon.Voiced.NULL, PhoneticType.CLICK),
	Consonant.cnsbuild("ǃ", PulCon.Shape.POSTALVEOLAR, PulCon.Voiced.NULL, PhoneticType.CLICK),
	Consonant.cnsbuild("ǂ", PulCon.Shape.PALATAL, PulCon.Voiced.NULL, PhoneticType.CLICK),
	Consonant.cnsbuild("𝼊", PulCon.Shape.RETROFLEX, PulCon.Voiced.NULL, PhoneticType.CLICK),
	Consonant.cnsbuild("ǁ", PulCon.Shape.LATERAL, PulCon.Voiced.NULL, PhoneticType.CLICK),
	#Voiced implosives
	Consonant.cnsbuild("ɓ", PulCon.Shape.BILABIAL, PulCon.Voiced.VOICED, PhoneticType.VOICED_IMPLOSIVE),
	Consonant.cnsbuild("ɗ", PulCon.Shape.ALVEOLAR, PulCon.Voiced.VOICED, PhoneticType.VOICED_IMPLOSIVE),
	Consonant.cnsbuild("ᶑ", PulCon.Shape.RETROFLEX, PulCon.Voiced.VOICED, PhoneticType.VOICED_IMPLOSIVE),
	Consonant.cnsbuild("ʄ", PulCon.Shape.PALATAL, PulCon.Voiced.VOICED, PhoneticType.VOICED_IMPLOSIVE),
	Consonant.cnsbuild("ɠ", PulCon.Shape.VELAR, PulCon.Voiced.VOICED, PhoneticType.VOICED_IMPLOSIVE),
	Consonant.cnsbuild("ʛ", PulCon.Shape.UVULAR, PulCon.Voiced.VOICED, PhoneticType.VOICED_IMPLOSIVE),
	#Ejective
	Consonant.cnsbuild("ʼ", PulCon.Shape.NULL, PulCon.Voiced.VOICED, PhoneticType.EJECTIVE),
	#Co-articulated Consonants
	CoCon.cobuild("ʍ", CoCon.Shape.VELAR, CoCon.Shape.BILABIAL, PhoneticType.PULMONIC_CONSONANT, CoCon.Voiced.UNVOICED),
	CoCon.cobuild("w", CoCon.Shape.VELAR, CoCon.Shape.BILABIAL, PhoneticType.PULMONIC_CONSONANT, CoCon.Voiced.VOICED),
	CoCon.cobuild("ɥ", CoCon.Shape.PALATAL, CoCon.Shape.BILABIAL, PhoneticType.PULMONIC_CONSONANT, CoCon.Voiced.VOICED),
	CoCon.cobuild("ɕ", CoCon.Shape.PALATAL, CoCon.Shape.LABIAL, PhoneticType.PULMONIC_CONSONANT, CoCon.Voiced.UNVOICED),
	CoCon.cobuild("ʑ", CoCon.Shape.PALATAL, CoCon.Shape.ALVEOLAR, PhoneticType.PULMONIC_CONSONANT, CoCon.Voiced.VOICED),
	CoCon.cobuild("ɧ", CoCon.Shape.POSTALVEOLAR, CoCon.Shape.VELAR, PhoneticType.PULMONIC_CONSONANT, CoCon.Voiced.NULL),
	#Stresses
	PhoneticFlag.build("ˈ", PhoneticType.PRIMARY_STRESS),
	PhoneticFlag.build("ˌ", PhoneticType.SECONDARY_STRESS),
	#Lengths
	PhoneticFlag.build("ː", PhoneticType.LONG),
	PhoneticFlag.build("ˑ", PhoneticType.HALF_LONG),
	PhoneticFlag.build("˘", PhoneticType.EXTRA_SHORT),
	PhoneticFlag.build(".", PhoneticType.SYLLABLE_BREAK),
	#Groups
	PhoneticFlag.build("ǀ", PhoneticType.MINOR_GROUP),
	PhoneticFlag.build("ǁ", PhoneticType.MAJOR_GROUP),
	#Linking
	PhoneticFlag.build("‿", PhoneticType.LINKING),
	#Ties (◌͡x & ◌͜x)
	PhoneticFlag.build("͡", PhoneticType.LINKING),
	PhoneticFlag.build(String.chr(8256), PhoneticType.LINKING),
	#Tones
	Tone.tnbuild("˥", 1),
	Tone.tnbuild("꜒", 1),
	Tone.tnbuild("˦", .5),
	Tone.tnbuild("꜓", .5),
	Tone.tnbuild("˧", 0),
	Tone.tnbuild("꜔", 0),
	Tone.tnbuild("˨", -.5),
	Tone.tnbuild("꜕", -.5),
	Tone.tnbuild("˩", -1),
	Tone.tnbuild("꜖", -1),
	#Steps
	PhoneticFlag.build("ꜛ", PhoneticType.UPSTEP),
	PhoneticFlag.build("ꜜ", PhoneticType.DOWNSTEP),
	#Diacritics
	Diacritic.dcbuild(" ̙̙", "Retracted tongue root"),
	Diacritic.dcbuild("̘", "Advanced tongue root"),
	Diacritic.dcbuild("̞", "Lowered"),
	Diacritic.dcbuild("̝", "Raised"),
	Diacritic.dcbuild("̴", "Velarized or pharyngealized"),
	Diacritic.dcbuild("̚", "No audible release"),
	Diacritic.dcbuild("̃", "Nasalized"),
	Diacritic.dcbuild("̻", "Laminal"),
	Diacritic.dcbuild("̼", "Linguolabial"),
	Diacritic.dcbuild("̰", "Creaky voiced"),
	Diacritic.dcbuild("̺", "Apical"),
	Diacritic.dcbuild("̤", "Breathy voiced"),
	Diacritic.dcbuild("̪", "Dental"),
	Diacritic.dcbuild(" ̥", "Voiceless"),
	Diacritic.dcbuild(" ̬", "Voiced"),
	Diacritic.dcbuild("ʰ", "Aspirated"),
	Diacritic.dcbuild(" ̹", "More rounded"),
	Diacritic.dcbuild("ʷ", "Labialized"),
	Diacritic.dcbuild(" ̜", "Less rounded"),
	Diacritic.dcbuild("ʲ", "Palatalized"),
	Diacritic.dcbuild("ⁿ", "Nasal release"),
	Diacritic.dcbuild(" ̟", "Advanced"),
	Diacritic.dcbuild("ˠ", "Velarized"),
	Diacritic.dcbuild("ˡ", "Lateral release"),
	Diacritic.dcbuild(" ̠", "Retracted"),
	Diacritic.dcbuild("ˁ", "Pharyngealized"),
	Diacritic.dcbuild(" ̈", "Centralized"),
	Diacritic.dcbuild(" ̽", "Mid-centralized"),
	Diacritic.dcbuild("̯", "Syllabic"),
	Diacritic.dcbuild("̩", "Non-syllabic"),
	Diacritic.dcbuild(" ̩", "Syllabic"),
	Diacritic.dcbuild(" ̯", "Non-syllabic"),
	Diacritic.dcbuild("˞", "Rhoticity"),
	Diacritic.dcbuild(" ͍", "Labial spreading"),
	Diacritic.dcbuild(" ͈", "Strong articulation"),
	Diacritic.dcbuild(" ͊", "Denasal"),
	Diacritic.dcbuild(" ͆", "Dentolabial"),
	Diacritic.dcbuild(" ͉", "Weak articulation"),
	Diacritic.dcbuild(" ͋", "Nasal escape"),
	Diacritic.dcbuild(" ̪͆", "Interdental/Bidental"),
	Diacritic.dcbuild("\\", "Reiterated articulation"),
	Diacritic.dcbuild(" ͌", "Velopharyngeal friction"),
	Diacritic.dcbuild(" ͇", "Alveolar"),
	Diacritic.dcbuild(" ͎", "Whistled articulation"),
	Diacritic.dcbuild("↓", "Ingressive airflow"),
	Diacritic.dcbuild(" ̼", "Linguolabial"),
	Diacritic.dcbuild(" ͢", "Sliding articulation"),
	Diacritic.dcbuild("↑", "Egressive airflow"),
	Diacritic.dcbuild(String.chr(776), "Combining diaeresis"),
	#Misc
	PhoneticFlag.build("(", PhoneticType.BRACKET_START),
	PhoneticFlag.build(")", PhoneticType.BRACKET_END),
	PhoneticFlag.build(" ", PhoneticType.MISC),
	PhoneticFlag.build("̈̈̈", PhoneticType.MISC),
]

static func phonetic_breakdown(inPhonetics : String) -> Dictionary:
	#Create the phonetic info collection
	var outPh : Array[PhoneticFlag] = []
	var trans : Transcription
	if inPhonetics.begins_with("/"):
		trans = Transcription.PHONEMIC
		inPhonetics = inPhonetics.trim_prefix("/").trim_suffix("/")
	elif inPhonetics.begins_with("["):
		trans = Transcription.PHONETIC
		inPhonetics = inPhonetics.trim_prefix("[").trim_suffix("]")
	else:
		trans = Transcription.UNKNOWN
	#Break the string down
	while inPhonetics.length() > 0:
		#Potential Flags
		var potFlags : Array[PhoneticFlag] = []
		for eachFlag in LOOKUP:
			if eachFlag.is_next(inPhonetics):
				potFlags.append(eachFlag)
		#If there's no valid valid flags, these are the fallbacks
		var bestFlag = PhoneticFlag.new(inPhonetics[0], PhoneticType.UNKNOWN)
		var bestLength : int = -1
		for eachFlag in potFlags:
			#Grab the flag with the longest length
			if eachFlag.name.length() > bestLength:
				bestLength = eachFlag.name.length()
				bestFlag = eachFlag
		#Remove the flag from the string
		inPhonetics = inPhonetics.trim_prefix(bestFlag.name)
		#Add it to the flags
		outPh.append(bestFlag)
	#Return this info
	return {"Transcription" : trans, "Flags" : outPh}
