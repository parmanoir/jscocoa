

	// Define a new class
	var newClass = JSCocoaController.createClass_parentClass("NSDerivedObjectTest", "NSObject")

	// Allocate instance
	var o = NSDerivedObjectTest.alloc.init
	o.release

	// Use [] accessor as 'class' is a reserved word in Javascript
	if (o['class'] != "NSDerivedObjectTest")	throw "derived object not created"


	// Derived a new class and add an overloaded method
	// Then derived from that new class
	
	
	// Record original hash
	var originalHash = o.hash
	
	// Overload hash method
	var wentThrough1 = false
	function	myHash()
	{
		var hash = this.Super(arguments)
		wentThrough1 = true
		return	hash
	}

	var added = JSCocoaController.overloadInstanceMethod_class_jsFunction('hash', NSDerivedObjectTest, myHash)
	if (!added)	throw "Couldn't overload method 1"

	// Check
	wentThrough1 = false
	var hash = o.hash
	if (hash != originalHash)	throw 'invalided hash in overloaded method'
	if (!wentThrough1)			throw 'invalided hash in overloaded method - did not go through'


	// Derivation of derivation
	var newClass = JSCocoaController.createClass_parentClass("NSDerivedObjectTest2", "NSDerivedObjectTest")
	
	// Allocate instance
	var o2 = NSDerivedObjectTest2.alloc.init
	o2.release

	// Record original hash
	var originalHash2 = o2.hash
	
	// Overload the same method
	var wentThrough2 = false
	function	myHash2()
	{
		var hash = this.Super(arguments)
		wentThrough2 = true
		return	hash
	}

	var added = JSCocoaController.overloadInstanceMethod_class_jsFunction('hash', NSDerivedObjectTest2, myHash2)
	if (!added)	throw "Couldn't overload method 2"

	// Check
	wentThrough1 = false
	wentThrough2 = false
	var hash2 = o2.hash
	if (hash2 != originalHash2)	throw 'invalided hash in overloaded method (2)'
	if (!wentThrough1)			throw 'invalided hash in overloaded method - did not go through 1st derivation'
	if (!wentThrough2)			throw 'invalided hash in overloaded method - did not go through 2nd derivation'
	
//	JSCocoaController.log('o=' + o['class']())
/*
	var originalRetainCount = o.retainCount

	// Try adding a method
	var i = 0
	var parentRetainCount
	function	myRetainCount()
	{
		i++
		log('============================================================')
		log('============================================================')
		log('============================================================')
		log('============================================================')
		log('============================================================')
		log('============================================================')
		log('============================================================')
		log('============================================================')
		log('============================================================')
		log('============================================================')
		log('============================================================')
		log('============================================================')
		log('============================================================')
		log('============================================================')
		parentRetainCount = this.Super(arguments)
		return	parentRetainCount
	}

	var added = JSCocoaController.overloadInstanceMethod_class_jsFunction('retainCount', NSDerivedObjectTest, myRetainCount)


	if (!added)	throw "Couldn't overload method 1"

	// Check original retain count, retain count from parent method, retain count from overload method
	var retainCountFromOverloadedMethod = o.retainCount
//	if (originalRetainCount != parentRetainCount || parentRetainCount != retainCountFromOverloadedMethod)	throw "invalid overloaded method"
	if (!hasObjCGC)
		if (i != 1)	throw "invalid overloaded method"

//	JSCocoaController.log('o=' + o.retainCount())

	
	// Derivation of derivation
	var newClass = JSCocoaController.createClass_parentClass("NSDerivedObjectTest2", "NSDerivedObjectTest")

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
	var added = JSCocoaController.overloadInstanceMethod_class_jsFunction('retainCount', NSDerivedObjectTest2, myRetainCount2)
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
*/
	o = null
	o2 = null

//	JSCocoaController.sharedController.cleanRetainCount(NSDerivedObjectTest)
