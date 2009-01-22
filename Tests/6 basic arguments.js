


	/*

		Test int, float, bool, strings

	*/

//	JSCocoaController.sharedController.evalJSFile(NSBundle.mainBundle.bundlePath + '/Contents/Resources/class.js')


	// Define a new class
	var newClass = JSCocoaController.createClass_parentClass("BasicArgumentsTester", "NSObject")

	// Test all encodings with a small float bias (0.1)
	// that bias will disappear during int conversion
	var	encodingsToTest = ['c', 'C', 's', 'S', 'i', 'I', 'f', 'd'];
	for (var i=0; i<encodingsToTest.length; i++)
	{
		var encoding = encodingsToTest[i]
		var encodingName = reverseEncodings[encoding]

		var fn			= new Function ('a', 'b', 'return a+b+0.1')
//		var fn			= new Function ('a', 'b', 'JSCocoaController.log("INADD (' + encoding + ') a="+a+" b=" + b); return a+b+0.1')
		var fnName		= 'test' + encoding + ':' + encoding + ':'
		var fnEncoding	= objc_encoding.apply(null, [encodingName, encodingName, encodingName]);

		JSCocoaController.addInstanceMethod_class_jsFunction_encoding(fnName, BasicArgumentsTester, fn, fnEncoding)
//		JSCocoaController.log('Adding method ' + fnName + ' with encoding ' + fnEncoding)
	}

	var tester = BasicArgumentsTester.alloc.init
	tester.release



	//
	// Test integer arguments
	//
	function	testerAssert(encoding, a, b, r)
	{
		var res = tester['test' + encoding + ':' + encoding + ':'](a, b)
//		JSCocoaController.log('r=' + r + ' res=' + res)
		if (r != res)	throw 'basic argument ' + encoding + ' failed : expected ' + r + ', got ' + res
	}
	
	testerAssert('c', 128, 2, -125)
	testerAssert('C', 128, 2, 130)
	testerAssert('s', 32768, 2, -32765)
	testerAssert('S', 32768, 2, 32770)
	testerAssert('i', 2147483648, 2, -2147483645)
	testerAssert('I', 2147483648, 2, 2147483650)
	


	//
	// Test float arguments
	//
	function	testerFloatAssert(encoding, a, b, r)
	{
		var res = tester['test' + encoding + ':' + encoding + ':'](a, b)
//		JSCocoaController.log('r=' + r + ' res=' + res)
		if (Math.abs(r-res) > 0.001)	throw 'basic argument ' + encoding + ' failed : expected ' + r + ', got ' + res
	}


	testerFloatAssert('f', -0.1234, 5.678, 5.6546)
	testerFloatAssert('d', -0.1234, 5.678, 5.6546)


	
	//
	// Test bool
	//
	var encoding = 'B'
	var encodingName = reverseEncodings[encoding]

	var fn			= new Function ('a', 'b', 'return a^b')
	var fnName		= 'test' + encoding + ':' + encoding + ':'
	var fnEncoding	= objc_encoding.apply(null, [encodingName, encodingName, encodingName]);

	JSCocoaController.addInstanceMethod_class_jsFunction_encoding(fnName, BasicArgumentsTester, fn, fnEncoding)
	
	var b = tester[fnName](true, false)
	if (b != true)	throw 'bool failed : true^false != true'
	var b = tester[fnName](false, false)
	if (b != false)	throw 'bool failed : false^false != false'
	var b = tester[fnName](true, true)
	if (b != false)	throw 'bool failed : true^true != false'
	
	
	
	//
	// Test strings
	//

	// Test selectors
	var encoding = ':'
	var encodingName = reverseEncodings[encoding]

	var fn			= new Function ('a', 'b', 'return a+b')
	var fnName		= 'testSEL:SEL:'
	var fnEncoding	= objc_encoding.apply(null, [encodingName, encodingName, encodingName]);

	JSCocoaController.addInstanceMethod_class_jsFunction_encoding(fnName, BasicArgumentsTester, fn, fnEncoding)

	var r = tester[fnName]('hello', 'world')
	if (r != 'helloworld')	throw 'string failed'
	var r = tester[fnName]('トピッ', 'クス')
	if (r != 'トピックス')	throw 'string failed'


	// Test char pointers
	var encoding = '*'
	var encodingName = reverseEncodings[encoding]

	var fn			= new Function ('a', 'b', 'return a+b')
	var fnName		= 'testCHARPTR:CHARPTR:'
	var fnEncoding	= objc_encoding.apply(null, [encodingName, encodingName, encodingName]);

	JSCocoaController.addInstanceMethod_class_jsFunction_encoding(fnName, BasicArgumentsTester, fn, fnEncoding)

	var r = tester[fnName]('hello', 'world')
	if (r != 'helloworld')	throw 'string failed'
	var 言葉 = tester[fnName]('トピッ', 'クス')
	if (言葉 != 'トピックス')	throw 'string failed'
	
//	JSCocoaController.log('r string=' + r)
	
	
	
	
	
	tester = null
	
	
	
	
	
	
