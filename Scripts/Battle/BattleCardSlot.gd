extends CardSlot
class_name BattleCardSlot

##The amount of damage this card has sustained
@export var damageMod : int
##If this card slot is controlled by the enemy
@export var enemySlot : bool
##The base vulnerability of the card slot
@export var baseVulnerability : int = 1
##The current vulnerability of the card
var vulnerability = 1
##The base speed of the card slot
@export var baseSpeed : int = 1
##The current speed of the card
var speed = 1
##The number of attacks taken this round
var roundAttacks : int = 0
##The number of attacks this card can take
var totalAttacks : int = 1

func _ready() -> void:
	reset_status()

##Reset this slots status
func reset_status():
	damageMod = 0
	vulnerability = baseVulnerability
	speed = baseSpeed
	totalAttacks = 1

##Calls when this card is attack
func is_attacked(attacker : BattleCardSlot) -> bool:
	var attackingCard := attacker.get_card()
	if attackingCard == null:
		push_error("Trying to attack from a null card slot!")
	var newDamage := int(attackingCard.uiCardDamage.text)
	damageMod += newDamage
	return get_card().apply_damage(damageMod)

##Check if there's attacks remaining
func attacks_remaining() -> bool:
	return roundAttacks < totalAttacks
