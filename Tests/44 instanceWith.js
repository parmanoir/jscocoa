

	//
	// [NSView instanceWith:var1 and:var2]
	// 
	
	var o1 = [NSString instanceWithString:'hello']
	if (!o1)									throw 'instanceWith failed (1)'
	if (![o1 isKindOfClass:NSString])			throw 'instanceWith failed (2)'


	var o2 = [NSURL instanceFileURLWithPath:@"/tmp" isDirectory:true]
	if (!o2)									throw 'instanceWith failed (3)'
	if (![o2 isKindOfClass:NSURL])				throw 'instanceWith failed (4)'

	
	o1 = null