
var device = MIDIGetDevice(0)

if (!device)
	throw 'No device'

var buffer = new memoryBuffer('@')
MIDIObjectGetStringProperty(device, kMIDIPropertyName, new outArgument(buffer, 0))

//log('Device from js: ' + device + ' name=' + buffer[0])
