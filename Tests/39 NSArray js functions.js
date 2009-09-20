

	//
	// If a method is not found in an NSArray, try to use the matching Javascript function
	//

		
	// Just testing the js function here.
	function	filterFn(o)
	{
//		log('el=' + o)
		return o.match(/^he/)
	}

	var jsArray = ['hello', 'world', 'he', 'hey', 'the']
	var jsFiltered = jsArray.filter(filterFn)
	log('jsArray=' + jsArray)
	log('jsArray filtered=' + jsFiltered)
	

	// Testing NSArray
	var array1 = NSMutableArray.array
	array1.addObjectsFromArray(jsArray)
	
	
	var filtered1 = array1.filter(filterFn)
	log('array1=' + array1)
	log('array1 filtered=' + filtered1)
	
	