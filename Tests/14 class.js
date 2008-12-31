

//	JSCocoaController.sharedController.evalJSFile(NSBundle.mainBundle.bundlePath + '/Contents/Resources/class.js')




	var testInstanceOverload	= false
	var testClassOverload		= false
	var testAdd					= false
	defineClass('MyTestObjectNewClass < NSObject', 
	{
		'performSelector:withObject:' : 
						function(sel, object)
						{
							var r = this.Super(arguments)
//							JSCocoaController.log('perform ' + sel + ' object=' + object)
							testInstanceOverload = true
							return	r
						}
		,'instanceMethodSignatureForSelector:' :
						function (sel)
						{
							var r = this.Super(arguments)
							testClassOverload = true
							return	r
						}
		,'someMethod:' :
						['id', 'id', function (o)
						{
							testAdd = true
							return o
						}]
		,'customAdd:And:' :
						['int', 'int', 'int', function (a, b)
						{
							return a+b
						}]
						
	})
	
	var o = MyTestObjectNewClass.instance
	
	// Test class overload
	MyTestObjectNewClass.instanceMethodSignatureForSelector('respondsToSelector:')
	
	// Test instance overload
	o.perform({ selector : 'someMethod:', withObject : o })
	
	// Test custom method
	var addResult = o.custom({ add : 4, and : 5 })
	
	if (!testClassOverload)		throw 'class method overload failed'
	if (!testInstanceOverload)	throw 'instance method overload failed'
	if (addResult != 9)			throw 'add instance method failed'


	o = null



	function	makeAdder(value)
	{
		return	function (a)
		{
			return a+value
		}
	}
	
	var fn = makeAdder(5)
//	JSCocoaController.log('r=' + fn(3))

	var hash = {}
	hash['closureTest:'] = ['int', 'int', fn]
	defineClass('MyTestObjectNewClass2 < NSObject', hash)
	
	var o = MyTestObjectNewClass2.instance
	var r = o.closureTest(8)
	
//	JSCocoaController.log('r=' + r)
	if (r != 13)	throw 'using a closure as instance method failed'

	o = null