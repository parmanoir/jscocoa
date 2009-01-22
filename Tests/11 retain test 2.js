




	/*

		Check JS's GC destroys objc instances

	*/

	JSCocoaController.garbageCollect
	
	
	// Cannot be tested as ObjC GC has no way of blocking the main thread to collect everything
	if (!hasObjCGC)
	{
		var newClass = JSCocoaController.createClass_parentClass("SomeRetainCountTest", "NSObject")

		var count0 = JSCocoaController.liveInstanceCount(SomeRetainCountTest)
		
		var o1 = newClass.alloc.init
		o1.release
		var o2 = newClass.instance()

		newClass.instance()
		
	//	JSCocoaController.logInstanceStats
		var count1 = JSCocoaController.liveInstanceCount(SomeRetainCountTest)
		if (count1 != 3)	throw 'invalid retain count - got '  + count1 + ', expected 3'
		
		o1 = null
		o2 = null
		
		JSCocoaController.garbageCollect

	//	JSCocoaController.logInstanceStats
		var count2 = JSCocoaController.liveInstanceCount(SomeRetainCountTest)
		if (count2 != 0)	throw 'invalid retain count - got '  + count2 + ', expected 0'

	//	JSCocoaController.log('***' + count0 + '***' + count1 + '***' + count2 + '***')
	//	JSCocoaController.logInstanceStats
	
	}