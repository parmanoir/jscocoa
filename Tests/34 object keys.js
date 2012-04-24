

	//
	// Given a javascript hash, return an array of its keys
	//
	
	var o = { name : 'hello', surname : 'world', someVariable : 1.25556 }

//	for (var i in o)	log('i=' + i)
//	log('allKeys=' + o.allKeys())

	var hasName			= false
	var hasSurname		= false
	var hasSomeVariable	= false
	var allKeys = Object.keys(o)
	for (var i=0; i<allKeys.length; i++)
	{
		var key = allKeys[i]
		if (key == 'name')			hasName			= true
		if (key == 'surname')		hasSurname		= true
		if (key == 'someVariable')	hasSomeVariable	= true
	}
	
	if (allKeys.length != 3)	throw 'invalid key count'
	if (!hasName)				throw 'key "name" not found'
	if (!hasSurname)			throw 'key "surname" not found'
	if (!hasSomeVariable)		throw 'key "someVariable" not found'
