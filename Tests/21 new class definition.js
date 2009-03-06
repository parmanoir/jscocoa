


//	JSCocoaController.sharedController.evalJSFile(NSBundle.mainBundle.bundlePath + '/Contents/Resources/class.js')



	Class('MyTestObjectNewClassNewMethod < NSObject').definition = function () 
	{

		Method('performSelector:withObject:').fn = function (a, b)
		{
			var r = this.Super(arguments)
			testInstanceOverload1 = true
			return	r
		}
		
		Method('instanceMethodSignatureForSelector:').fn = function (a, b)
		{
			var r = this.Super(arguments)
			testClassOverload1 = true
			return	r
		}
		Method('someMethod:').encoding('id id').fn = function (o)
		{
			testAdd = true
			return o
		}
		Method('customAdd:And:').encoding('int int int').fn = function (a, b)
		{
			return a+b
		}

		IBOutlet('outlet1')
		IBOutlet('outlet2').setter = function (newValue)
		{
			outletSetter = true
			// DO NOT DO THIS — THIS WILL GO INTO AN INFINITE RECURSIVE SETPROPERTY CALL
//			this.outlet2 = newValue

			// Use this.
			this.set({jsValue:newValue, forJsName : '_outlet2' })
		}

		IBAction('clickedStuff').fn = function (sender) 
		{
			actionCalled = sender
		}
		
		Key('MyKey1')
		
		// Custom key setters and getters — add an underscore or raw JSValueForJSName will take precedence over getter
		Key('MyKey2').setter = function (newValue)
		{
			calledKeySetter = true
			this.set({jsValue:newValue, forJsName : '_MyKey2' })
		}
		Key('MyKey2').getter = function ()
		{
			calledKeyGetter = true
			return this.JSValueForJSName('_MyKey2')
		}
	}

	Class('MyTestObjectNewClassNewMethod2 < MyTestObjectNewClassNewMethod').definition = function () 
	{
		Method('performSelector:withObject:').fn = function (a, b)
		{
			var r = this.Super(arguments)
			testInstanceOverload2 = true
			return	r
		}
		Method('instanceMethodSignatureForSelector:').fn = function (a, b)
		{
			var r = this.Super(arguments)
			testClassOverload2 = true
			return	r
		}
	}


	//
	// Test derivation
	//
	var testInstanceOverload1	= false
	var testClassOverload1		= false
	

	var o1 = MyTestObjectNewClassNewMethod.instance()
		

	// Test class overload
	MyTestObjectNewClassNewMethod.instanceMethodSignatureForSelector('respondsToSelector:')
	if (!testClassOverload1)	throw 'class method overload failed'
	
	// Test instance overload
	var testAdd					= false
	o1.perform({ selector : 'someMethod:', withObject : o1 })
	if (!testInstanceOverload1)	throw 'instance method overload failed '
	if (!testAdd)				throw 'instance method overload failed b'
	
	// Test custom method
	var addResult = o1.custom({ add : 4, and : 5 })
	if (addResult != 9)			throw 'add instance method failed'

	// Test outlet
	var outletSetter			= false
	o1.setOutlet1('hello')
	o1.setOutlet2('world')
	if (o1.outlet1 != 'hello')	throw 'outlet failed'
	if (!outletSetter)			throw 'outlet custom setter failed 1'
	if (o1.outlet2 != 'world')	throw 'outlet custom setter failed 2'
	
	// Test action
	var actionCalled			= null
	o1.perform({ selector : 'clickedStuff:', withObject : 5 })
	if (actionCalled != 5)		throw 'action failed'
	
		
	// Test key
	var	calledKeySetter			= false
	var	calledKeyGetter			= false
	o1.setMyKey1('Test clé')
	if (o1.MyKey1 != 'Test clé')	throw 'MyKey1 failed'

	o1.setMyKey2('Test clé 2')
	if (o1.MyKey2 != 'Test clé 2')	throw 'MyKey2 failed'

	if (!calledKeySetter)		throw 'custom key setter failed'
	if (!calledKeyGetter)		throw 'custom key getter failed'

	//
	// Test derivation of derivation
	//
	var testInstanceOverload1	= false
	var testInstanceOverload2	= false
	var testClassOverload1		= false
	var testClassOverload2		= false


	var o2 = MyTestObjectNewClassNewMethod2.instance()
	
	// Test class overload
	MyTestObjectNewClassNewMethod2.instanceMethodSignatureForSelector('respondsToSelector:')
	
	// Test instance overload
	var testAdd					= false
	o2.perform({ selector : 'someMethod:', withObject : o1 })
	
	if (!testClassOverload1)	throw 'class method overload failed 1'
	if (!testInstanceOverload1)	throw 'instance method overload failed 1'
	if (!testClassOverload2)	throw 'class method overload failed 2 '
	if (!testInstanceOverload2)	throw 'instance method overload failed 2'



	o1 = null
	o2 = null
