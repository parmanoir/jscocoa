

	/*
		-objectAtIndex: in Cocoa Uncanny Valley
		http://rentzsch.tumblr.com/post/266777783/objectatindex-in-cocoa-uncanny-valley
	
		Fixed. Exception is caught in callAsFunction_ffi, then boxed back to Javascript.
	*/


	var gotIntoCatchBlock
	try
	{
		log([[NSArray arrayWithObjects:@"a", @"b", nil] objectAtIndex:-1])
	}
	catch(e)
	{
		gotIntoCatchBlock = true
//		log('got an ObjC exception ' + e.name + '\n' + e.reason)
		
		if (e.name != 'NSRangeException')		throw 'NSArray range exception failed (1)'
		if (!e.reason.match(/objectAtIndex/))	throw 'NSArray range exception failed (2)'
	}
	
	if (!gotIntoCatchBlock)						throw 'NSArray range exception failed (3)'
