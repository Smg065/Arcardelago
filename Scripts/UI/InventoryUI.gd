extends Control
class_name InventoryUI

##Displays the spheres you have.
@export var sphereIcons : Array[TextureRect]
##Displays the money you have.
@export var goldLabel : Label
##Displays the hint points.
@export var hintPointLabel : Label
##Displays the house level.
@export var houseUpgradeLabel : Label
##Displays the backdrops of reachable regions.
@export var backdropStrips : Array[ColorRect]

@export_category("Base")
##The region bars that show what you've found.
@export var foundBars : Array[ProgressBar]
##The region bars that show what you've released.
@export var releasedBars : Array[ProgressBar]
##The text that displays your progress in each region.
@export var foundReleasedText : Array[Label]

@export_category("Obstacle Breakers")
##The icons that display what region item busters you have
@export var obsticalBreakerIcons : Array[TextureRect]

@export_category("Stamps")
##The icons that display what region item busters you have
@export var stampIcons : Array[TextureRect]
##The icons that display what region item busters you have
@export var stampCounts : Array[Label]
