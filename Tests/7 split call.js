
	// Split call disabled by default since ObjJ syntax
	var useSplitCall = __jsc__.useSplitCall
	__jsc__.useSplitCall = true

	
//	JSCocoaController.sharedController.evalJSFile(NSBundle.mainBundle.bundlePath + '/Contents/Resources/class.js')

	// Define a new class
	var newClass = JSCocoaController.createClass_parentClass("SplitCallTester", "NSObject")
	
	//
	// Test bool
	//
	var encoding = '*'
	var encodingName = reverseEncodings[encoding]

	var fn			= new Function('a', 'b', 'c', 'return a+b+c')
	var fnName		= 'performSomeTest:withObject:andObject:'
	var fnEncoding	= objc_encoding.apply(null, [encodingName, encodingName, encodingName, encodingName]);
	

//	JSCocoaController.log('Adding method ' + fnName + ' with encoding ' + fnEncoding)
	JSCocoaController.addInstanceMethod_class_jsFunction_encoding(fnName, SplitCallTester, fn, fnEncoding)
	
	var o = SplitCallTester.alloc.init
	o.release
	
	var a = 'hello'
	var b = 'world'
	var c = '!'

	var r1 = o.performSomeTest_withObject_andObject(a, b, c)
	var r2 = o.performSomeTest_withObject_andObject_(a, b, c)
	var r3 = o['performSomeTest:withObject:andObject:'](a, b, c)

	var r4 = o.perform( {	 someTest : a
							,withObject : b
							,andObject : c } )


/*
	JSCocoaController.log('r1=' + r1)
	JSCocoaController.log('r2=' + r2)
	JSCocoaController.log('r3=' + r3)
	JSCocoaController.log('r4=' + r4)
*/	
	if (r1 != 'helloworld!' || r1 != r2 || r1 != r3 || r1 != r4)	throw 'split call failed'
	
	o = null
	
	__jsc__.useSplitCall = useSplitCall
	