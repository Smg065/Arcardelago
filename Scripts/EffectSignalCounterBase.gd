extends ESB
##The base of Event Signal Handlers that count when things happen
class_name ESCB

##The instances of the effect count
var count : int

##Sets the current count
func set_count(toSet, ...args):
	count = toSet
	update.emit(self, args)

##Adds to the current count
func add_count(toAdd, ...args):
	count += toAdd
	update.emit(self, args)

##Removes from the current count
func remove_count(toRemove, ...args):
	count -= toRemove
	update.emit(self, args)
