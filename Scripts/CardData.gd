extends Resource
class_name CardData

##The name of the player that has this card.
var playerName : String
##The game cardset this card comes from.
var gameCardset : GameCardset
##The name data associated with the Card Data.
var nameData : NameData
##The item you can find at this card's location.
var apId : int
##If this card is a location, its address
var apAddress : int
##The quality of the item
var apItemFlags : int
##If this card is a location instead of an item.
var enemyCard : bool
##The angle color fades has on this.
var fadeAngle : float
##If this card has no item attacked.
@export var isDefault : bool
##If this card is from your Arcardelago.
var isLocal : bool
##The points this card is worth
var powerScore : int

var debugColorScores : Dictionary[ColorCatagory.ColorTypes, float]
##The health this card has by default.
var baseHealth : int = 1
##The attack this card has by default.
var baseAttack : int = 1
##The abilities this card has
var abilities : Array[CardAbilityBundle]
##The stamp info on this card
var stamps : PackedStringArray

@export_flags("Red", "Green", "Violet", "Orange", "Blue", "Yellow") var colors : int = 0

const RED = ColorCatagory.ColorTypes.RED
const GREEN = ColorCatagory.ColorTypes.GREEN
const VIOLET = ColorCatagory.ColorTypes.VIOLET
const ORANGE = ColorCatagory.ColorTypes.ORANGE
const BLUE = ColorCatagory.ColorTypes.BLUE
const YELLOW = ColorCatagory.ColorTypes.YELLOW

static func build(newApItemFlags : int, newApId : int, newData : NameData, newGameCardset : GameCardset, newPlayer : String, newIsLocal : bool, newEnemyCard : bool = false, newApAddress = -1) -> CardData:
	var cardData := CardData.new()
	cardData.playerName = newPlayer
	cardData.apId = newApId
	cardData.apAddress = newApAddress
	cardData.gameCardset = newGameCardset
	cardData.nameData = newData
	cardData.enemyCard = newEnemyCard
	cardData.apItemFlags = newApItemFlags
	cardData.fadeAngle = randf_range(0, 2*PI)
	cardData.isLocal = newIsLocal
	#Enemy cards are the locations of your items
	if cardData.enemyCard:
		cardData.gameCardset.enemyCards.append(cardData)
	#Player cards are your items
	else:
		cardData.gameCardset.playerCards.append(cardData)
	cardData.colors = cardData.calculate_color()
	cardData.stat_card()
	return cardData

func json_save():
	if isDefault:
		return {"isDefault" : true}
	var abilityDict : Array[Dictionary] = []
	for eachAbility in abilities:
		abilityDict.append(eachAbility.json_save())
	var saveOutput : Dictionary = {
		"playerName" : playerName,
		"apId" : apId,
		"nameData" : nameData.name,
		"apItemFlags" : apItemFlags,
		"enemyCard" : enemyCard,
		"apAddress" : apAddress,
		"fadeAngle" : fadeAngle,
		"isLocal" : isLocal,
		"isDefault" : false,
		"baseHealth" : baseHealth,
		"baseAttack" : baseAttack,
		"powerScore" : powerScore,
		"abilities" : abilityDict
	}
	return saveOutput

static func json_load(inDict, gameData : GameData) -> CardData:
	var cardData := CardData.new()
	if inDict["isDefault"]:
		cardData.isDefault = true
		return
	cardData.playerName = inDict["playerName"]
	cardData.apId = inDict["apId"]
	cardData.apItemFlags = inDict["apItemFlags"]
	cardData.enemyCard = inDict["enemyCard"]
	cardData.apAddress = inDict["apAddress"]
	cardData.fadeAngle = inDict["fadeAngle"]
	cardData.isLocal = inDict["isLocal"]
	cardData.baseHealth = inDict["baseHealth"]
	cardData.baseAttack = inDict["baseAttack"]
	cardData.powerScore = inDict["powerScore"]
	cardData.nameData = gameData.existingNames[inDict["nameData"]]
	for eachGame in gameData.gameCardsets:
		if gameData.gameCardsets[eachGame].players.has(cardData.playerName):
			cardData.gameCardset = gameData.gameCardsets[eachGame]
			if cardData.enemyCard:
				gameData.gameCardsets[eachGame].enemyCards.append(cardData)
			else:
				gameData.gameCardsets[eachGame].playerCards.append(cardData)
				break
	cardData.colors = cardData.calculate_color()
	for eachAbility in inDict["abilities"]:
		cardData.abilities.append(CardAbilityBundle.json_load(eachAbility))
	return cardData

##Creates a default card
static func new_default(nIsEnemy : bool = false) -> CardData:
	var output := CardData.new()
	output.enemyCard = nIsEnemy
	output.isDefault = true
	output.stat_card()
	return output

##The flags used for this card as displayed as basic text
func stringify_item_quality() -> String:
	#Enemies
	if enemyCard:
		return "Location"
	if isDefault:
		return "Default"
	#Proguseful
	if apItemFlags == 3:
		return "Proguseful"
	#Trap
	elif apItemFlags >= 4:
		return "Trap"
	#Progression
	elif apItemFlags == 1:
		return "Progression"
	#Useful
	elif apItemFlags == 2:
		return "Useful"
	#Filler
	return "Filler"

##Get the points on the card and pick abilities from it
func stat_card() -> void:
	##Points used for statting cards in general
	var pointsAvailable : int = 0
	#Default Cards just have base health and attack
	if isDefault:
		baseHealth = 1
		baseAttack = 1
		return
	#Otherwise, lot more to consider
	
	##The RNG used by this card name
	var rng = RandomNumberGenerator.new()
	rng.set_seed(hash(nameData.name) + hash(gameCardset.nameData))
	
	#Pick the points you can use next
	match stringify_item_quality():
		"Filler":
			powerScore = 6
		"Useful":
			powerScore = 12
		"Progression":
			powerScore = 18
		"Proguseful":
			powerScore = 24
		"Trap":
			powerScore = 24
		"Location":
			#Bosses
			if apItemFlags == 3:
				powerScore = 30
			else:
				powerScore = rng.randi_range(3, 27)
	pointsAvailable = powerScore
	##The points used to modify stats
	var forStatroll : int = 0
	##Highest number of abilities this card can have based on power score
	var maxAbilities : int = clampi(floori(powerScore / 2.0) - 1, 0, 3)
	var weights := PackedFloat32Array()
	for eachAbility in maxAbilities + 1:
		match eachAbility:
			0:
				weights.append(2)
			1:
				weights.append(5)
			2:
				weights.append(2)
			3:
				weights.append(1)
	##The number of abilities this card has
	var abilityCount = rng.rand_weighted(weights)
	##The health this card has
	var healthPoints : int = 1
	##The attack this card has
	var attackPoints : int = 1
	
	#Leave at least 2 point per each ability minimum
	if abilityCount > 0:
		forStatroll = rng.randi_range(0, pointsAvailable - (abilityCount * 2))
	else:
		#No abilities, means all points go into stats
		forStatroll = pointsAvailable
	
	##How much attack you have. for. Statroll - statRatio becomes how much health you have.
	var statRatio : int = rng.randi_range(0, forStatroll) + rng.randi_range(0, forStatroll)
	statRatio /= 2
	attackPoints += statRatio
	healthPoints += forStatroll - statRatio
	baseHealth = healthPoints
	baseAttack = attackPoints
	
	##The amount of points used for ability tags.
	var forTags : int = pointsAvailable - forStatroll
	##Get the number of points that can shift (all ability tags need 2)
	var distributable = forTags - (abilityCount * 2)
	var randomWeights := PackedFloat32Array()
	var randomPoints := PackedInt32Array()
	var weightSum : float = 0
	#Decide how many of the distributable points each ability gets
	for _i in abilityCount:
		var eachWeight := rng.randf()
		weightSum += eachWeight
		randomWeights.append(eachWeight)
	var pointSum : int = 0
	#Get the minimum absolute required
	for weightIndex in randomWeights.size():
		var result = randomWeights[weightIndex] * distributable / weightSum
		randomPoints.append(floori(result))
		randomWeights[weightIndex] = result - randomPoints[weightIndex]
		randomPoints[weightIndex] += 2
		pointSum += randomPoints[weightIndex]
	#Cleanup remainder
	while pointSum < forTags:
		var results := PD.get_best(range(randomWeights.size()), PD.square_bracket.bind(randomWeights))
		var resultIndex : int = PD.seeded_pick_random(rng, results)
		randomWeights[resultIndex] -= 1
		randomPoints[resultIndex] += 1
		pointSum += 1
	#Give the amount of points to each entry
	for eachPoints in randomPoints:
		var thing := CSM.construct_abiity(eachPoints, [], [])
		abilities.append(thing)

##Check if the item has been released or the location has been cleared
func is_cleared() -> bool:
	if isDefault:
		return false
	if enemyCard:
		for eachItem in Archipelago.conn.received_items:
			if eachItem.loc_id == apAddress:
				return true
	else:
		return Archipelago.conn.slot_locations[apId]
	return false

##A packed string array of the litteral names of the colors
func stringify_colors() -> PackedStringArray:
	var output : PackedStringArray
	if colors & 0b000001:
		output.append("Red")
	if colors & 0b000010:
		output.append("Green")
	if colors & 0b000100:
		output.append("Violet")
	if colors & 0b001000:
		output.append("Orange")
	if colors & 0b010000:
		output.append("Blue")
	if colors & 0b100000:
		output.append("Yellow")
	if output.size() == 0:
		output.append("Colorless")
	return output

##The flags used for this card as displayed on a Card UI
func rich_item_flags() -> String:
	#Enemies
	if enemyCard:
		return "[hint=A check which contains an item in your world][bgcolor=LIGHT_GREEN][color=BLACK]Location"
	if isDefault:
		return "[hint=No item in this card][bgcolor=SLATE_GREY][color=BLACK]Default"
	#Proguseful
	if apItemFlags == 3:
		return "[hint=An item that is critical for progression][bgcolor=GOLD][color=BLACK]Proguseful"
	#Trap
	elif apItemFlags >= 4:
		return "[hint=An item that actively hinders the owner][bgcolor=SALMON][color=BLACK]Trap"
	#Progression
	elif apItemFlags == 1:
		return "[hint=An item that can unlock checks][bgcolor=PLUM][color=BLACK]Progression"
	#Useful
	elif apItemFlags == 2:
		return "[hint=An item that while not required, is especially useful][bgcolor=SLATEBLUE][color=WHITE]Useful"
	#Filler
	return "[hint=An unimportant item][bgcolor=CYAN][color=BLACK]Filler"

func rich_phonetic_symbols() -> PackedStringArray:
	return nameData.rich_text_unique_phonetics()

func unique_parts_of_speech():
	var allParts = nameData.get_parts_of_speech()
	var uniqueDict : Dictionary[String, int] = {}
	for eachPart in allParts:
		if not uniqueDict.has(eachPart):
			uniqueDict[eachPart] = 1
		else:
			uniqueDict[eachPart] += 1
	var outString := PackedStringArray([])
	for eachUnique in uniqueDict:
		outString.append(eachUnique.capitalize() + " x" + str(uniqueDict[eachUnique]))
	return outString

func calculate_color() -> int:
	var colorScore : Dictionary[ColorCatagory.ColorTypes, float] = {}
	for baseColor in ColorCatagory.BASE_COLORS:
		#Create the default entry
		var colorType : ColorCatagory.ColorTypes = baseColor.colorType
		colorScore[colorType] = 0
		#Get the Set's Values
		colorScore[colorType] += gameCardset.colorScore[colorType]
		#Source Pref Flags
		match baseColor.itemSourcePref:
			ColorCatagory.SourcePref.LOCAL:
				if isLocal:
					colorScore[colorType] += ColorCatagory.MULTI_SOURCE
			ColorCatagory.SourcePref.EXTERNAL:
				if not isLocal:
					colorScore[colorType] += ColorCatagory.MULTI_SOURCE
		#Item Quality Flags are Player Only
		if !enemyCard:
			if baseColor.itemQualityFlags.has(apItemFlags):
				colorScore[colorType] += ColorCatagory.MULTI_ITEM_FLAGS * baseColor.itemQualityMulti
		#Go over the name flags
		for eachFlag in nameData.nameFlags:
			colorScore[colorType] += eachFlag.get_score(baseColor)
	
	debugColorScores = colorScore
	
	return scores_to_color(colorScore)

static func scores_to_color(colorScore, multi : float = 1) -> int:
	var useColors : Array[ColorCatagory.ColorTypes] = []
	var highestRunnerUp : float = 0
	var runnerUpsForUse : Array[ColorCatagory.ColorTypes] = []
	for eachColor in colorScore:
		if colorScore[eachColor] >= 100 * multi:
			useColors.append(eachColor)
		elif colorScore[eachColor] >= 50 * multi:
			#Append Ties
			if is_equal_approx(highestRunnerUp, colorScore[eachColor]):
				runnerUpsForUse.append(eachColor)
			#Overwrite Best Color Score
			elif highestRunnerUp < colorScore[eachColor]:
				highestRunnerUp = colorScore[eachColor]
				runnerUpsForUse.clear()
				runnerUpsForUse.append(eachColor)
	useColors.append_array(runnerUpsForUse)
	#Get the color type flags
	var outColor : int = 0
	for eachEntry in useColors:
		match eachEntry:
			ColorCatagory.RED:
				outColor += 1
			ColorCatagory.GREEN:
				outColor += 2
			ColorCatagory.VIOLET:
				outColor += 4
			ColorCatagory.ORANGE:
				outColor += 8
			ColorCatagory.BLUE:
				outColor += 16
			ColorCatagory.YELLOW:
				outColor += 32
	return outColor

##If this card could combine with another as a UI
func is_comparable(otherCard : CardData) -> bool:
	#Yourself is valid
	if otherCard == self:
		return true
	#Otherwise, a few checks;
	if enemyCard != otherCard.enemyCard:
		return false
	#If it's a default, they must both be
	if isDefault or otherCard.isDefault:
		return isDefault == otherCard.isDefault
	#Same game at least
	if gameCardset.game != otherCard.gameCardset.game:
		return false
	#Same item flags
	if apItemFlags != otherCard.apItemFlags:
		return false
	#Compare Names
	return nameData.name == otherCard.nameData.name

##Returns the int represenation of the cards quality
func card_quality() -> int:
	#Quality Floor
	if isDefault:
		return 0
	if enemyCard:
		return 0
	match apItemFlags:
		#Filler
		0:
			return 2
		#Useful
		2:
			return 3
		#Progression
		1:
			return 4
		#Proguseful
		3:
			return 5
		#Traps (>=4)
		_:
			return 1

##Calculate the value of this card data
func card_value(useDifficulty : bool = true) -> int:
	var output := card_quality() + 1
	if enemyCard:
		output = ceili(powerScore / 6.0) + 2
	#Stamp Prices increase the value
	for eachStamp in stamps:
		match eachStamp:
			"Steel":
				output += 1
			"Harmony":
				output += 2
			"Ghost":
				output += 3
			"Square":
				output += 2
			"Gold":
				output += 3
	if !useDifficulty:
		return output
	match Persist.difficulty:
		1:
			output = floori(output * 1.5)
		2:
			output = output * 2
	return output

##Scouts the APID to the players
func scout():
	if isDefault or enemyCard:
		push_error("Cannot Scout This Item!")
		return
	if !Persist.game.knownLoctions.has(apId):
		Persist.game.knownLoctions.append(apId)
	Archipelago.conn.scout(apId, 2, Persist.game.itemHandler.new_known_card)
##Releases the item in the card to the APWorld
func release():
	if isDefault or enemyCard:
		push_error("Cannot Release This Item!")
	Archipelago.collect_location(apAddress)
	Persist.lose_card(self)
