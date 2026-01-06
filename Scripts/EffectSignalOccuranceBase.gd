extends ESB
##A variant of Effect Signals that counts occurances of a specific type
class_name ESOB

##The instances of the effect occurances
var occurances : Array

##Adds to the current occurance list
func add_occurance(toAdd, ...args):
	occurances.append(toAdd)
	print(occurances)
	update.emit(self, args)

##Removes from the current occurance list
func remove_occurance(toRemove, ...args):
	occurances.erase(toRemove)
	print(occurances)
	update.emit(self, args)
