

	// Split call disabled by default since ObjJ syntax
	var useSplitCall = __jsc__.useSplitCall
	__jsc__.useSplitCall = true




	var instance1 = NSString.stringWithString('hello')
	var instance2 = NSString.alloc.initWithString('hello')
	instance2.release
	var instance3 = NSString.alloc.ini( { tWithString : 'hello' } )
	instance3.release
	// Disabled thanks to ObjJ syntax, which is just a much better way : [Class instanceWith...]
//	var instance4 = NSString.instance( { withString : 'hello' } )
	var instance4 = NSString.instanceWithString('hello')
	var instance5 = NSString.instance

	var instance6 = NSString.alloc.init
	var instance7 = NSString.alloc.init

	if (instance1 != 'hello')	throw "(1) Invalid string instance"
	if (instance2 != 'hello')	throw "(2) Invalid string instance"
	if (instance3 != 'hello')	throw "(3) Invalid string instance"
	if (instance4 != 'hello' || instance4['class'] != 'NSCFString')						throw "(4) Invalid string instance"
	if (instance5 != '' || instance5.length != 0 || instance5['class'] != 'NSCFString')	throw "(5) Invalid string instance"
	if (instance6 != '' || instance6.length != 0 || instance6['class'] != 'NSCFString')	throw "(6) Invalid string instance"
	if (instance7 != '' || instance7.length != 0 || instance7['class'] != 'NSCFString')	throw "(7) Invalid string instance"


	__jsc__.useSplitCall = useSplitCall



	//
	// Test NSLocale alloc
	//

	var a = NSLocale.alloc.initWithLocaleIdentifier('fr_FR')
	a.release

	__jsc__.useAutoCall = false
	
	var a = NSLocale.alloc().initWithLocaleIdentifier('fr_FR')
	
	if (!a.isKindOfClass(NSLocale))			throw "(8) Non autocall alloc failed"
	if (a.localeIdentifier() != 'fr_FR')	throw "(9) Non autocall alloc failed"
	a.release()
	
	var a = NSLocale.instanceWithLocaleIdentifier('fr_FR')
	
	__jsc__.useAutoCall = true
