extends ESB
##A variant of Effect Signals that counts occurances of a specific type
class_name ESOB

##The instances of the effect occurances
var occurances : Array

##Make the current occurance list this array
func set_occurances(toSet, ...args):
	occurances = toSet
	update.emit(self, args)

##Adds to the current occurance list
func add_occurance(toAdd, ...args):
	occurances.append(toAdd)
	update.emit(self, args)

##Removes from the current occurance list
func remove_occurance(toRemove, ...args):
	occurances.erase(toRemove)
	update.emit(self, args)
