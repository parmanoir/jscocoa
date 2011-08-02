

	/*

		Test if an ObjC object boxed multiple times is equal to itself :
		NSWorkspace.sharedWorkspace == NSWorkspace.sharedWorkspace
		should be true.
		
		Sounds obvious but Javascript has no callback to compare.

	*/


	var obj1 = NSWorkspace.sharedWorkspace
	var obj2 = NSWorkspace.sharedWorkspace
	
//	log('obj1 == obj2=' + (obj1 == obj2))
	
//	log(JSCocoaController.boxedObjects)
	if (obj1 != obj2)	throw 'obj1 != obj2'

	obj1 = null
	obj2 = null

//	JSCocoa.garbageCollect
//	log(JSCocoaController.boxedObjects)


//	log(NSApplication == NSApplication)
//	log(NSApplication.sharedWorkspace == NSApplication.sharedWorkspace)
//	log(NSString.stringWithString('j') == NSString.stringWithString('j'))


	var v = NSView.alloc.init
	v.release