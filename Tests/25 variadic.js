
	/*
	
		A variadic call accepts a variable number of arguments.
		
		ObjC
			NSArray.arrayWithObjects(a, b, c, ..., nil)
			
		C
			NSLog(format, var1, var2, ...)
		
	
	*/


//	log(jsc.typeEncodingOfMethod_class('arrayWithObjects:', 'NSArray'))
//	log(jsc.typeEncodingOfMethod_class('instantiateNibWithOwner:topLevelObjects:', 'NSNib'))

	// Bad format - to check NSLogConsole async output 
//	var format = "kMDItemDisplayName like[cdw] '*jscocoa*') and (kMDItemFSName like[c] \"*\.jscocoa\")"


	// Check exactitude of a full predicate with a predicate built with arguments
	var format = "(kMDItemDisplayName like[cdw] '*jscocoa*') and (kMDItemFSName like[c] \"*\.jscocoa\")"
	var p1 = NSPredicate.predicateWithFormat(format)
	var p2 = NSPredicate.predicateWithFormat("(kMDItemDisplayName like[cdw] %@) and (kMDItemFSName like[c] %@)", '*jscocoa*', '*.jscocoa')

	if (String(p1) != String(p2))			throw 'variadic call failed (1)'


	// Check array building
	var array = NSArray.arrayWithObjects(1.23, 'hello', 5.67, null)
	
	if (array.length != 3)					throw 'variadic call failed (2)'
	if (array[0].valueOf() != 1.23)			throw 'variadic call failed (3)'
	if (array[1].valueOf() != 'hello')		throw 'variadic call failed (4)'
	if (array[2].valueOf() != 5.67)			throw 'variadic call failed (5)'
	
	// Check array building with a derived class
	var array = NSMutableArray.arrayWithObjects(1.23, 'hello', 5.67, null)
	
	if (array.length != 3)					throw 'variadic call failed (6)'
	if (array[0].valueOf() != 1.23)			throw 'variadic call failed (7)'
	if (array[1].valueOf() != 'hello')		throw 'variadic call failed (8)'
	if (array[2].valueOf() != 5.67)			throw 'variadic call failed (9)'

	// C variadic call
	// Works, but how to test it ?
//	NSLog('%@ %@ %@', 5, 'hello', NSArray.array)
	