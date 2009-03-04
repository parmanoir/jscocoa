
	/*
		Create an autorelease object
		setup a timer
		do nothing more … yet
		the autorelease will kick in, lowering the autoreleased object's retain count.
			BUT ! as the Javascript object is retaining it, it does not die.

		then we're called back :
		delete the last reference to the object by setting its variable to null
		call garbage collect
		test that the object was deallocated
	*/
	var deallocatedMyTestObject = false
	function	myDealloc()
	{
//		JSCocoaController.log('>>>>autoReleasedObject=' + this + ' count=' + this.retainCount())
		JSCocoaController.log('>>>>MyTestObject=' + this + ' DEALLOC')
		deallocatedMyTestObject = true
		return	this.Super(arguments)
	}
	function	myRetain()
	{
		JSCocoaController.log('MyTestObject =>retain ' + this.retainCount())
		var r = this.Super(arguments);
		JSCocoaController.log('MyTestObject =>retain ' + this.retainCount())
		return	r
	}
	function	myRelease()
	{
		JSCocoaController.log('MyTestObject RELEASE ' + this.retainCount())
		var r = this.Super(arguments);
//		JSCocoaController.log('MyTestObject RELEASE ' + this.retainCount())
		return	r
	}
	var newClass = JSCocoaController.sharedController().createClass_parentClass("MyTestObject", "CALayer")
	var added = JSCocoaController.sharedController().overloadInstanceMethod_class_jsFunction('dealloc', objc_getClass("MyTestObject"), myDealloc)
//	var added = JSCocoaController.sharedController().overloadInstanceMethod_class_jsFunction('retain', objc_getClass("MyTestObject"), myRetain)
//	var added = JSCocoaController.sharedController().overloadInstanceMethod_class_jsFunction('release', objc_getClass("MyTestObject"), myRelease)

	var autoReleasedObject = MyTestObject.layer()

	JSCocoaController.log('autoReleasedObject=' + autoReleasedObject + ' count=' + autoReleasedObject.retainCount())


	function	performSelectorTarget(notif)
	{
		JSCocoaController.log('about to release autoReleasedObject=' + autoReleasedObject + ' count=' + autoReleasedObject.retainCount())
		autoReleasedObject = null
		// This will dealloc object in a next run loop run ...
		JSCocoaController.garbageCollect()
		JSCocoaController.garbageCollect()
		JSCocoaController.garbageCollect()
		JSCocoaController.garbageCollect()
		JSCocoaController.garbageCollect()
		
//		if (!deallocatedMyTestObject)	JSCocoaController.logAndSay('retainCount - object was not deallocated')
		// ... so set a timer to be there and check it then.
		o.performSelector_withObject_afterDelay('callMe2:', null, 0.1)
	}

	function	performSelectorTarget2(notif)
	{
		if (!deallocatedMyTestObject)	JSCocoaController.logAndSay('retainCount - object was not deallocated')
	}

	function	objc_encoding()
	{
		var encodings = { 	 'void' : 'v'
							,'id' : '@'
							}
		var encoding = encodings[arguments[0]]
		encoding += '@:'
		
		for (var i=1; i<arguments.length; i++)	encoding += encodings[arguments[i]]
		return	encoding
	}
	
	// Define a new class
	var newClass = JSCocoaController.sharedController().createClass_parentClass("PerformSelectorTester", "NSObject")
//	JSCocoaController.log('encoding=' + objc_encoding('void', 'id'))
	var added = JSCocoaController.sharedController().addInstanceMethod_class_jsFunction_encoding('callMe:', objc_getClass("PerformSelectorTester"), performSelectorTarget, objc_encoding('void', 'id'))
	var added = JSCocoaController.sharedController().addInstanceMethod_class_jsFunction_encoding('callMe2:', objc_getClass("PerformSelectorTester"), performSelectorTarget2, objc_encoding('void', 'id'))
	
	var o = PerformSelectorTester.alloc().init()

				
	o.performSelector_withObject_afterDelay('callMe:', null, 0)

