

	// Define a new class
	var newClass = JSCocoaController.sharedController.createClass_parentClass("NSDerivedObjectTest", "NSObject")

	// Allocate instance
	var o = NSDerivedObjectTest.alloc.init
	o.release

	// Use [] accessor as class is reserved in Javascript
	if (o['class'] != "NSDerivedObjectTest")	throw "derived object not created"
	
//	JSCocoaController.log('o=' + o['class']())

	var originalRetainCount = o.retainCount

	// Try adding a method
	var i = 0
	var parentRetainCount
	function	myRetainCount()
	{
		i++
		parentRetainCount = this.Super(arguments)
		return	parentRetainCount
	}

	var added = JSCocoaController.sharedController.overloadInstanceMethod_class_jsFunction('retainCount', NSDerivedObjectTest, myRetainCount)


	if (!added)	throw "Couldn't overload method 1"

	// Check original retain count, retain count from parent method, retain count from overload method
	var retainCountFromOverloadedMethod = o.retainCount
//	if (originalRetainCount != parentRetainCount || parentRetainCount != retainCountFromOverloadedMethod)	throw "invalid overloaded method"
	if (!hasObjCGC)
		if (i != 1)	throw "invalid overloaded method"

//	JSCocoaController.log('o=' + o.retainCount())

	
	// Derivation of derivation
	var newClass = JSCocoaController.sharedController.createClass_parentClass("NSDerivedObjectTest2", "NSDerivedObjectTest")

	// Allocate instance
	var o2 = NSDerivedObjectTest2.alloc.init
	o2.release
	
	// Overload the same method
	var parentRetainCount2
	function	myRetainCount2()
	{
		i += 10
		parentRetainCount2 = this.Super(arguments)
		return	parentRetainCount2
	}
	var added = JSCocoaController.sharedController.overloadInstanceMethod_class_jsFunction('retainCount', NSDerivedObjectTest2, myRetainCount2)
	if (!added)	throw "Couldn't overload method 2"


	// Undefine that to check NSDerivedObject's method is called
	parentRetainCount = undefined
	i = 0

	var retainCountFromOverloadedMethod2 = o2.retainCount
//	JSCocoaController.log('parentRetainCount=' + parentRetainCount)
//	JSCocoaController.log('parentRetainCount2=' + parentRetainCount2)
//	JSCocoaController.log('retainCountFromOverloadedMethod2=' + retainCountFromOverloadedMethod2)
//	JSCocoaController.log('i=' + i)


//
//	if (		originalRetainCount != parentRetainCount2 
//			||	parentRetainCount != retainCountFromOverloadedMethod2 
//			||	parentRetainCount2 != retainCountFromOverloadedMethod2 
//			||	i != 11)	throw "invalid second overloaded method"
//
	// retainCount not called during GC
	if (!hasObjCGC)
		if (i != 11)	throw "invalid second overloaded method"

	o = null
	o2 = null

//	JSCocoaController.sharedController.cleanRetainCount(NSDerivedObjectTest)
