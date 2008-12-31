

	// Load file
	var file = NSBundle.mainBundle.bundlePath + '/Contents/Resources/Tests/Resources/externalFileTest.js'
//	JSCocoaController.log(file)
	JSCocoaController.sharedController.evalJSFile(file)

	// Test var
	if (externalVariable != 'Hello !')	throw "external variable not found"

	// Test function
	var added = externalFunctionAdder(3, 4)
	if (added != 7)	throw "external function malfunctioned"
	
//	JSCocoaController.log('added=' + added)
