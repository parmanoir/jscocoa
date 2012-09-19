
var getName = function(object) {
	var name = new outArgument;
	
	MIDIObjectGetStringProperty(object, kMIDIPropertyName, name)
	return name;
};

var device = MIDIGetDevice(0);
//log("Device from js: " + getName(device));

if (!device)
	throw 'No device'
