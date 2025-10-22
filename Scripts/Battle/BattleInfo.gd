extends Resource
class_name BattleInfo

enum BattleType {DEFAULT, RIVAL, BOSS, FINAL_BOSS}
var region : int
var difficulty : int
var type : BattleType

##Calulate the difficulty of this battle
func calculate_difficulty(toRegionBoss : float) -> void:
	#Start with the region depth
	##How close this world is to the end of the game
	var regionDepth : int = 0
	#White is the max depth, otherwise use the node depth
	if region == 0:
		regionDepth = Persist.gameDepth
	else:
		regionDepth = Persist.dfsRegions[PD.REGION_TO_NAME[region]]
	##How close this node is to the end of the game, on a scale from 0 to 1
	var gameProgress : float = (toRegionBoss + regionDepth) / float(Persist.gameDepth + 1)
	difficulty = roundi(Persist.end_game_difficulty() * gameProgress)
