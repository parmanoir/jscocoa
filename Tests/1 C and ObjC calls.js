	

	// Test C call
	var time = CFAbsoluteTimeGetCurrent()
	if (typeof time != "number")	throw "invalid type"
	
	// Obj C call
	var numBundles = NSBundle.allBundles.count
	
	if (numBundles < 1)				throw "no bundles found"
	
//	JSCocoaController.log(NSBundle.allBundles().objectAtIndex(0))
//	var r = JSCocoaController.garbageCollect()
//	JSCocoaController.log('About to call')
//	JSCocoaController.log('r=' + r)
