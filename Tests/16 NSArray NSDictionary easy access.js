


	/*
	
		Check boxing : JSCocoaFFIArgument.fromJSValueRef 
			array.addObject(5)		-> NSNumber
			array.addObject('hello) -> NSString


		Check unboxing : callAsFunction (valueOf)
		
			array[0] = 'string'
			
			array[1] + 1 == 'string1'
			
			array[1] = 5
			array[1] + 1 == 6, NOT '51'
			
	
	*/

	var a = NSMutableArray.instance
	
	
	
	a.addObject(5.0)
	a.addObject('Hello')

	if ((a.objectAtIndex(0) + 1) != 6)			throw 'number unboxing failed'
	if ((a.objectAtIndex(1) + 1) != 'Hello1')	throw 'string unboxing failed'

	a = null

	/*
		Check array JS-like access :
		
			array[0] = value
			value == array[0]
			
			array.length (duplicate of ObjC's array.count)
	*/
	var a = NSMutableArray.instance
	
	a.addObject(6.0)
	a.addObject('Hello World !')

	// Bracket get
	if ((a[0] + 1) != 7)				throw 'array bracket get [] failed'
	if ((a[1] + 1) != 'Hello World !1')	throw 'array bracket get [] failed (2)'
	
	// Bracket set
	a[0] = 7.0
	a[1] = 'HOY !'

	if ((a[0] + 1) != 8)				throw 'array bracket set [] failed'
	if ((a[1] + 1) != 'HOY !1')			throw 'array bracket set [] failed (2)'


	if (a.length != 2)					throw '[array count] not accessible via array.length'
	a = null

	/*
		Check hash JS-like access :
			
			hash['someKey'] = value
			value == hash['someKey']


		for (key in hash)
	*/
	var d = NSMutableDictionary.instance
	
//	d.set({ object : 13.0, forKey : 'key1' })
//	JSCocoaController.log('d.key1=' + d.objectForKey('key1'))

	d.key1 = 13
	d['key2'] = 'Wieder'
	
	
//	JSCocoaController.log('d.key1=' + d.valueForKey('key1'))
//	JSCocoaController.log('d.key2=' + d.valueForKey('key2'))


	if ((d.valueForKey('key1') + 1) != 14)			throw 'dictionary set failed'
	if ((d.valueForKey('key2') + 1) != 'Wieder1')	throw 'dictionary set failed (2)'
	
	if ((d.key1 + 1) != 14)							throw 'dictionary get failed'
	if ((d['key2'] + 1) != 'Wieder1')				throw 'dictionary get failed (2)'


	/*
	
		Check hash enum

	*/
	d.key3 = 'hello'
	d.key4 = 'world'

	var gotKey1 = false
	var gotKey2 = false
	var gotKey3 = false
	var gotKey4 = false
	for (key in d)
	{
//		JSCocoaController.log('got key ' + key + ' = ' + d[key])
		if (key == 'key1')	gotKey1 = true
		if (key == 'key2')	gotKey2 = true
		if (key == 'key3')	gotKey3 = true
		if (key == 'key4')	gotKey4 = true
	}
	
	if (!gotKey1 || !gotKey2 || !gotKey3 || !gotKey4)	throw 'dictionary enum failed'
	
	
	d = null
	
	

	/*

		Test a 'straight out of Cocoa' dictionary

	*/
	var app = NSWorkspace.sharedWorkspace.activeApplication

	// Change that as we could be inactive - check that identifier has two dots
//	if (app.NSApplicationBundleIdentifier != 'com.inexdo.JSCocoa')	throw 'dictionary get failed (3)'
	if (app.NSApplicationBundleIdentifier.match(/\./g).length != 2)	throw 'dictionary get failed (3)'

//	JSCocoaController.log('app=' + app['class'])

//	JSCocoaController.log('Running ' + NSWorkspace.sharedWorkspace.activeApplication.NSApplicationName)
