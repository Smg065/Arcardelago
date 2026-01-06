extends RefCounted
##The base of Event Signal Handlers that count when things happen
class_name ESB

##The info about this effect
var info : EffectSignalInfo

##Calls when all cards that care about this should trigger
@warning_ignore("unused_signal")
signal update
