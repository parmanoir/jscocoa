
	log('*********fix 3 derivation*************')


	// Define a new class
	var newClass = JSCocoaController.createClass_parentClass("NSDerivedObjectTest", "NSObject")
	
	var o = NSDerivedObjectTest.alloc.init
	o.release
	o = null
	

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

	o = null
	o2 = null
