


	// Kinda void now as autocall is always on
	
	var appName1 = NSWorkspace.sharedWorkspace.activeApplication.objectForKey('NSApplicationName')
	var appName2 = NSWorkspace.sharedWorkspace.activeApplication.objectForKey('NSApplicationName')
//	JSCocoaController.log('appName1=' + appName1)
//	JSCocoaController.log('appName2=' + appName2)

	var numBundles1 = NSBundle.allBundles.count
	var bundles = NSBundle.allBundles
	var numBundles2 = bundles.count
//	JSCocoaController.log('numBundles1=' + numBundles1)
//	JSCocoaController.log('numBundles2=' + numBundles2)
	
	if (String(appName1) != String(appName2))	throw 'zeroarg caller failed 1'
	if (String(appName1) != String(appName2))	throw 'zeroarg caller failed 2'
	
//	log(typeof numBundles1)
//	log(typeof numBundles2)
	if (numBundles1 != numBundles2)				throw 'zeroarg valueOf caller failed'
