
	/*
	
		Treat NSStrings as native JS strings 

	*/


	// Replace
	var str = NSString.stringWithString('hello').replace(/ll/, 'mm')
	if (str != 'hemmo')	throw 'NSString bridging failed 1'

	// Split
	var r = NSString.stringWithString('helmlo').split('l')
	if (r.length != 3 || r[0] != 'he' || r[1] != 'm' || r[2] != 'o')	throw 'NSString bridging failed 2'
	
	// Replace on a bundle identifier — BAD as it will fail if id starts with something else (like VLC, org.videolan.vlc)
//	var str = NSWorkspace.sharedWorkspace.activeApplication.NSApplicationBundleIdentifier.substr(0, 3)
//	if (str != 'com')	throw 'NSString bridging failed 3'

	// Javascript
	var str1 = NSWorkspace.sharedWorkspace.activeApplication.NSApplicationBundleIdentifier.substr(0, 3)
	// ObjC
	var str2 = NSWorkspace.sharedWorkspace.activeApplication.NSApplicationBundleIdentifier.substringWithRange(NSMakeRange(0, 3))
	// Check equivalence of JS and ObjC
	if (str1 != str2.valueOf())	throw 'NSString bridging failed 3'
