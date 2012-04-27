

	//
	// JSON handling of native ObjC classes
	//


	var date	= [NSDate date]
	var dict	= [NSDictionary dictionaryWithObjectsAndKeys:@"Hello", @"brave", [NSNumber numberWithInteger:100], @"kosmos", date, @"now"]

/*
	// Moved to json.js, to be loaded separately

	// String JSON method
	String.prototype.toJSON = function () { return this }

	// Javascript JSON methods for native classes
	//	These need to return Javascript values, not boxed ObjC objects
	class_add_js_function(NSNumber,		'toJSON', function ()	{ return this.valueOf() } )
	class_add_js_function(NSDate,		'toJSON', function ()	{ return String(this.description) } )
	class_add_js_function(NSArray,		'toJSON', function ()	{ 
				var r = []
				for (var i=0; i<this.length; i++)
					r.push(this[i].toJSON())
				return r
			} )
	class_add_js_function(NSDictionary,	'toJSON', function ()	{ 
				var r = {}
				var keys = Object.keys(this)
				for (var i=0; i<keys.length; i++)
					r[keys[i]] = this[keys[i]].toJSON()
				return r
			} )
*/

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
	

	//
	// NSArray test
	//
	var array	= [NSArray arrayWithObjects:@"Look", @"up", @"down", nil]
	var json	= JSON.stringify(array)
	var o		= JSON.parse(json).sort()
	if (o.length != 3)				throw 'JSON failed (7)'
	if (o[0] != 'Look')				throw 'JSON failed (8)'
	if (o[1] != 'down')				throw 'JSON failed (9)'
	if (o[2] != 'up')				throw 'JSON failed (10)'

//	log("JSON.stringify(theNSArray) " + JSON.stringify(array))
//	log('o=' +o)
	
	
	//
	// Embedded dictionary and array test
	//
	var dict	= [NSDictionary dictionaryWithObjectsAndKeys:"up", "key1", "down", "key2"]
	var dict2	= [NSDictionary dictionaryWithObjectsAndKeys:array, @"array", dict, @"dict", @"Hello", @"brave", [NSNumber numberWithInteger:100], @"kosmos", [NSDate date], @"now"]
	
	var json	= JSON.stringify(dict2)
	var o		= JSON.parse(json)
//	log('json=' + json)
//	log('o=' + dumpHash(o))
//	log('o.dict=' + dumpHash(o.dict))
	
	if (Object.keys(o).length != 5)	throw 'JSON failed (11)'

	// Embedded array
	var o2		= o.array.sort()
	if (o2.length != 3)				throw 'JSON failed (12)'
	if (o2[0] != 'Look')			throw 'JSON failed (13)'
	if (o2[1] != 'down')			throw 'JSON failed (14)'
	if (o2[2] != 'up')				throw 'JSON failed (15)'
	
	// Embeded dict
	var o2		= o.dict
	var keys	= Object.keys(o2).sort()
	if (keys.length != 2)			throw 'JSON failed (16)'
	if (keys[0] != 'key1')			throw 'JSON failed (17)'
	if (keys[1] != 'key2')			throw 'JSON failed (18)'
	if (o2.key1 != 'up')			throw 'JSON failed (19)'
	if (o2.key2 != 'down')			throw 'JSON failed (20)'
	
	
	