

	//
	// If a method is not found in an NSArray, try to use the matching Javascript function.
	//
	//	NSArray.arrayWithObjects('hello', 'world').filter( javascript function )
	//	(filter being a function from Array.prototype)
	//

		
	function	filterFn(o)
	{
//		log('el=' + o)
		return o.match(/^he/)
	}

	var jsArray = ['hello', 'world', 'he', 'hey', 'the']

	// Just testing the js function here.
	var jsFiltered = jsArray.filter(filterFn)
//	log('jsArray=' + jsArray)
//	log('jsArray filtered=' + jsFiltered)
	

	// Testing NSArray ...
	
	// filter
	var array1 = NSMutableArray.array
	array1.addObjectsFromArray(jsArray)
	
	var filtered = array1.filter(filterFn)
//	log('array1=' + array1)
//	log('array1 filtered=' + filtered)
	if (filtered.length != 3)	throw 'NSArray function bridge failed (1)'
	if (filtered[0] != 'hello')	throw 'NSArray function bridge failed (2)'
	if (filtered[1] != 'he')	throw 'NSArray function bridge failed (3)'
	if (filtered[2] != 'hey')	throw 'NSArray function bridge failed (4)'
	
	// map
	var array2 = NSMutableArray.arrayWithObjects(1, 2, 3, null)
	var mapped = array2.map(function (o) { return o*2 })
//	log('array2=' + array2)
//	log('array2 mapped=' + mapped)
	if (mapped.length != 3)		throw 'NSArray function bridge failed (5)'
	if (mapped[0] != 2)			throw 'NSArray function bridge failed (6)'
	if (mapped[1] != 4)			throw 'NSArray function bridge failed (7)'
	if (mapped[2] != 6)			throw 'NSArray function bridge failed (8)'

	