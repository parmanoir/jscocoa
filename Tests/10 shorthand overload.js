
//	JSCocoaController.sharedController.evalJSFile(NSBundle.mainBundle.bundlePath + '/Contents/Resources/class.js')


	// Shorthand notation for over(ride|load)ing

	JSCocoa.create( { 'class' : 'ShorthandOverloadTest', parentClass : 'NSObject' } )
	JSCocoa.create( { 'class' : 'ShorthandOverloadTest2', parentClass : 'ShorthandOverloadTest' } )


	function	fn(a, b, c)
	{
		return '1' + a + '2' + b + '3' + c + '4'
	}
	var added = JSCocoa.addInstanceMethod_class_jsFunction_encoding('performStuff:withThis:andThat:', ShorthandOverloadTest, fn, objc_encoding('charpointer', 'charpointer', 'charpointer', 'charpointer'))

	function	fn2Add(a, b)
	{
		return a+b
	}
	var added = JSCocoa.addInstanceMethod_class_jsFunction_encoding('add:and:', ShorthandOverloadTest, fn2Add, objc_encoding('int', 'int', 'int'))

	var o = ShorthandOverloadTest2.alloc.init

	o['performStuff:withThis:andThat:'] =	function (a, b, c)
											{
												return '^' + a + '!' + b + '?' + c + '$' + this.Super(arguments)
											}
	

	var shorthandOnClassWorked = false
	ShorthandOverloadTest2['add:and:'] =	function (a, b)
											{
												var r = this.Super(arguments)
												shorthandOnClassWorked = true
												return r+1
											}

	var r = o.add_and_(3, 5)
	if (r != 9)						throw 'shorthand overload on class failed'
	if (!shorthandOnClassWorked)	throw 'shorthand overload on class failed'

//	ShorthandOverloadTest2

	var a = 'hello'
	var b = 'small'
	var c = 'world'
	var r = o['performStuff:withThis:andThat:'](a, b, c)
//	JSCocoaController.log('r=' + r)
	if (r != ('^' + a + '!' + b + '?' + c + '$' + '1' + a + '2' + b + '3' + c + '4'))	throw	'shorthand overload failed'


	// LATER : Direct add method via assign ?
//	o['someSelector:'] = {	 fn : function ...
//							,encoding : ... }


	o.release
	o = null