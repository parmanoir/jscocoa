

	/*
		
		Define a class deriving from an ObjC class
		
		defineClass('ChildClass < ParentClass', 
			,'overloadedMethod:' :
							function (sel)
							{
								var r = this.Super(arguments)
								testClassOverload = true
								return	r
							}
			,'newMethod:' :
							['id', 'id', function (o)  // encoding + function
							{
								testAdd = true
								return o
							}]
			,'myOutlet' : 'IBOutlet'
			,'myAction' : ['IBAction', 
							function (sender)
							{
							}]
						
		})

	*/




	function	defineClass(inherit, methods)
	{
		var s = inherit.split('<')
		var className = s[0].replace(/ /gi, '')
		var parentClassName = s[1].replace(/ /gi, '')
		if (className.length == 0 || parentClassName.length == 0)	throw 'Invalid class definition : ' + inherit

		// Get parent class
		var parentClass = this[parentClassName]
		if (!parentClass)											throw 'Parent class ' + parentClassName + ' not found'
//		JSCocoaController.log('parentclass=' + parentClass)

		var c = JSCocoaController.sharedController
		var newClass = c.create({ 'class' : className, parentClass : parentClassName})
		
		for (var method in methods)
		{
			var isInstanceMethod = parentClass.instancesRespondToSelector(method)
			var isOverload = parentClass.respondsToSelector(method) || isInstanceMethod
//			JSCocoaController.log('adding method *' + method + '* to ' + className + ' isOverload=' + isOverload + ' isInstanceMethod=' + isInstanceMethod)
			
			if (isOverload)
			{
				var fn = methods[method]
				if (!fn || (typeof fn) != 'function')	throw 'Method ' + method + ' not a function'

				if (isInstanceMethod)	c.overload({ instanceMethod : method, 'class' : newClass, jsFunction : fn })
				else					c.overload({ classMethod : method, 'class' : newClass, jsFunction : fn })
			}
			else
			{
				// Extract encodings
				var encodings = methods[method]
				
				// IBOutlet
				if (encodings == 'IBOutlet')
				{
					var outletMethod = 'set' + method.substr(0, 1).toUpperCase() + method.substr(1) + ':'
					var encoding = objc_encoding('void', 'id')

					var fn = new Function('outlet', 'this.set({jsValue:outlet, forJsName : "_' + method + '"})')
					c.add({ instanceMethod : outletMethod, 'class' : newClass, jsFunction : fn, encoding : encoding })

					var fn = new Function('return this.JSValueForJSName("_' + method + '")')
					var encoding = objc_encoding('id')
					
					c.add({ instanceMethod : method, 'class' : newClass, jsFunction : fn, encoding : encoding })					
				}
				else
				// IBAction
				if (encodings.length == 2 && encodings[0] == 'IBAction' && (typeof encodings[1] == 'function'))
				{
					var fn = encodings[1]
					if (method.charAt(method.length-1) != ':')	method += ':'
					var encoding = objc_encoding('void', 'id')
					c.add({ instanceMethod : method, 'class' : newClass, jsFunction : fn, encoding : encoding })					
				}
				else
				// Key
				if (encodings == 'Key')
				{
					// Get
					var fn = new Function('return this.JSValueForJSName("' + method + '")')
					c.add({ instanceMethod : method, 'class' : newClass, jsFunction : fn, encoding : objc_encoding('id') })
					// Set
					var setMethod = 'set' + method.substr(0, 1).toUpperCase() + method.substr(1) + ':'
					var fn = new Function('v', 'this.set({jsValue:v, forJsName : "' + method + '"})')
					c.add({ instanceMethod : setMethod, 'class' : newClass, jsFunction : fn, encoding : objc_encoding('void', 'id') })
				}
				else
				// New method
				{
					if (typeof encodings != 'object' || !('length' in encodings))	throw 'Invalid definition of ' + method + ' in ' + inherit + ' ' + (typeof encodings) + ' ' + (encodings.length)
					// Extract method
					var fn = encodings.pop()
					if (!fn || (typeof fn) != 'function')	throw 'New method ' + method + ' not a function'
					
					var encoding = objc_encoding.apply(null, encodings)
					c.add({ instanceMethod : method, 'class' : newClass, jsFunction : fn, encoding : encoding })
				}
			}
		}
		return	newClass
	}
