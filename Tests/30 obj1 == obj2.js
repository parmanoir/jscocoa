

	/*
		

	*/



	var obj1 = NSWorkspace.sharedWorkspace
	var obj2 = NSWorkspace.sharedWorkspace
	
//	log('obj1 == obj2=' + (obj1 == obj2))
	
	if (obj1 != obj2)	throw 'obj1 != obj2'
	
	obj1 = null
	obj2 = null
	
	//
	// Test a second time to see if cache clears up OK
	//




//	throw '30 obj1 == obj2'
