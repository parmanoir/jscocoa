
/*
	var instance1 = NSButton123.alloc.init
	instance1.release
	var instance2 = NSButton123.alloc().init()
	instance2.release
	
	// Autocall instancing will happen ...
	var instance3 = NSButton123.instance
	// ... on property get
	instance3['class']
	var instance4 = NSButton123.instance()
*/	
/*
	var instance5 = NSButton123.instance( { withString1 : 'hello', andString2 : 'world' } )
	
	instance1 = null
	instance2 = null
	instance3 = null
	instance4 = null
	instance5 = null
	
	JSCocoaController.garbageCollect
*/







	var instance1 = NSString.stringWithString('hello')
	var instance2 = NSString.alloc.initWithString('hello')
	instance2.release
	var instance3 = NSString.alloc.ini( { tWithString : 'hello' } )
	instance3.release
	var instance4 = NSString.instance( { withString : 'hello' } )
	var instance5 = NSString.instance()

	var instance6 = NSString.alloc.init
	var instance7 = NSString.alloc.init

	if (instance1 != 'hello')	throw "(1) Invalid string instance"
	if (instance2 != 'hello')	throw "(2) Invalid string instance"
	if (instance3 != 'hello')	throw "(3) Invalid string instance"
	if (instance4 != 'hello' || instance4['class'] != 'NSCFString')						throw "(4) Invalid string instance"
	if (instance5 != '' || instance5.length != 0 || instance5['class'] != 'NSCFString')	throw "(5) Invalid string instance"
	if (instance6 != '' || instance6.length != 0 || instance6['class'] != 'NSCFString')	throw "(6) Invalid string instance"
	if (instance7 != '' || instance7.length != 0 || instance7['class'] != 'NSCFString')	throw "(7) Invalid string instance"


/*


	var instance1 = NSString.stringWithString('hello')
	var instance2 = NSString.alloc.initWithString('hello')
	instance2.release
	var instance3 = NSString.alloc.ini( { tWithString : 'hello' } )
	instance3.release
	var instance4 = NSString.instance( { withString : 'hello' } )
	JSCocoaController.log('***INSTANCE')
	var instance5 = NSString.instance
	JSCocoaController.log('****GOING')
	instance5.length
	instance5.isEqualToString('')
	JSCocoaController.log('*****GONE')
	var instance6 = NSURL.instance( { withString : '/Applications', relativeToURL : NSURL.URLWithString('/Developer') } )
	var instance7 = NSString.alloc.init
	var instance8 = NSString.alloc.init()
	var instance9 = NSString.instance()
	
	JSCocoaController.log('instance1=' + instance1 + ' length=' + instance1.length)
	JSCocoaController.log('instance2=' + instance2)
	JSCocoaController.log('instance3=' + instance3)
	JSCocoaController.log('instance4=' + instance4)
	JSCocoaController.log('instance5=' + instance5 + ' length=' + instance5.length)
	JSCocoaController.log('instance6=' + instance6)
	JSCocoaController.log('instance7=' + instance7 + ' length=' + instance7.length)
	JSCocoaController.log('instance8=' + instance8 + ' length=' + instance8.length)
	JSCocoaController.log('instance9=' + instance9 + ' length=' + instance9.length)
	
	JSCocoaController.garbageCollectNow
*/	

/*
	var c1 = JSCocoaController.JSCocoaPrivateObjectCount
//	var c1 = Number(JSCocoaController.JSCocoaPrivateObjectCount)
	var o2 = NSString.instance
//	o2.blah = 'hello'
	
//	JSCocoaController.log('o2=' + o2)
	var o3 = NSString.instance
	var i = o3.length
//	JSCocoaController.log('o3=' + o3 + ' i=' + i)
	
	var o4 = NSString.instance( { withString : 'hello' } )
//	JSCocoaController.log('o4=' + o4)
	var o5 = NSString.instance()
//	JSCocoaController.log('o5=' + o5)




//	var c2 = JSCocoaController.JSCocoaPrivateObjectCount


//	JSCocoaController.log('o2=' + o2['class'])

	
	o1 = o2 = o3 = o4 = o5 = null
	JSCocoaController.garbageCollect
	
	for (a in this)	if (a != 'c1')	this[a] = null
//	var c3 = JSCocoaController.JSCocoaPrivateObjectCount
//	JSCocoaController.log('count=' + c1 + ' ' + c2 + ' ' + c3)
	JSCocoaController.log('count=' + c1 + ' hc=' + JSCocoaController.JSCocoaHashCount)
	JSCocoaController.log('eq=' + (NSString.instance == ''))
*/

/*
	JSCocoaController.log('start')
	var o = NSString.instance
	JSCocoaController.log('inited')
	JSCocoaController.log('instanceA=' + o)
	
	
*/
/*


	var appName1 = NSWorkspace.sharedWorkspace().activeApplication().objectForKey('NSApplicationName')
	var appName2 = NSWorkspace.sharedWorkspace.activeApplication.objectForKey('NSApplicationName')
//	JSCocoaController.log('appName1=' + appName1)
//	JSCocoaController.log('appName2=' + appName2)

	var numBundles1 = NSBundle.allBundles().count()
	var bundles = NSBundle.allBundles
	var numBundles2 = bundles.count
//	JSCocoaController.log('numBundles1=' + numBundles1)
//	JSCocoaController.log('numBundles2=' + numBundles2)
	JSCocoaController.log('start')
	JSCocoaController.log('=' + appName1)
	JSCocoaController.log('end')
	if (String(appName1) != String(appName2))	throw 'zeroarg caller failed'
	if (String(appName1) != String(appName2))	throw 'zeroarg caller failed'
	
	if (numBundles1 != numBundles2)				throw 'zeroarg valueOf caller failed'
*/	