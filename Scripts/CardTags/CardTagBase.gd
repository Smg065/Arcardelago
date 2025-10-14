extends Resource
##The root of all card tag effects
class_name CardTagBase
##The colors this tag belongs to
@export_flags("Red", "Green", "Violet", "Orange", "Blue", "Yellow") var colors : int = 0

##How much this particular tag costs[br]
## 6 Points - Filler Items[br]
##12 Points - Useful Items[br]
##18 Points - Progresison Items[br]
##24 Points - Proguseful Items[br]
@export var cost : int
