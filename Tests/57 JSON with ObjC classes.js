

	//
	// JSON handling of native ObjC classes
	//


	var date	= [NSDate date]
	var dict	= [NSDictionary dictionaryWithObjectsAndKeys:@"Hello", @"brave", [NSNumber numberWithInteger:100], @"kosmos", date, @"now"]

	// String JSON method
	String.prototype.toJSON = function () { return this }

	// Javascript JSON methods for native classes
	//	These need to return Javascript values, not boxed ObjC objects
	class_add_js_function(NSNumber, 'toJSON', function ()	{ return this.valueOf() } )
	class_add_js_function(NSDate, 'toJSON', function ()		{ return String(this.description) } )

	// Convert to JSON and back
	var json	= JSON.stringify(dict)
//	log('r=' + json)
	var o		= JSON.parse(json)
//	log('o=' + dumpHash(o))
	
	var keys	= Object.keys(o).sort()
//	log('keys=' + keys)
	
	if (keys.length != 3)			throw 'JSON failed (1)'
	if (keys[0] != 'brave')			throw 'JSON failed (2)'
	if (keys[1] != 'kosmos')		throw 'JSON failed (3)'
	if (keys[2] != 'now')			throw 'JSON failed (4)'

	if (o.brave != 'Hello')			throw 'JSON failed (5)'
	if (o.kosmos != 100)			throw 'JSON failed (6)'
	if (o.now != String(date.description))			throw 'JSON failed (7)'
	
	
	