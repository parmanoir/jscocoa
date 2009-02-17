
	function	log(str)	{	JSCocoaController.log('' + str)	}
	
	function	dumpHash(o)	{	var str = ''; for (var i in o) str += i + '=' + o[i] + '\n'; return str }

	// A global variable named __jsc__ set by JSCocoaController in each context
//	var jsc = JSCocoaController.hasSharedController ? JSCocoaController.sharedController : null
	var jsc = __jsc__

	/*
		
		Pretty print of ObjC type encodings
		http://developer.apple.com/documentation/Cocoa/Conceptual/ObjectiveC/Articles/chapter_13_section_9.html#//apple_ref/doc/uid/TP30001163-CH9-113054
		
	*/


	var encodings = { 	
		 'id'			: '@'
		,'class'		: '#'
		,'selector'		: ':'
		,'char'			: 'c'
		,'uchar'		: 'C'
		,'short'		: 's'
		,'ushort'		: 'S'
		,'int'			: 'i'
		,'uint'			: 'I'
		,'long'			: 'l'
		,'ulong'		: 'L'
		,'longlong'		: 'q'
		,'ulonglong'	: 'Q'
		,'float'		: 'f'
		,'double'		: 'd'
		,'bool'			: 'B'
		,'void'			: 'v'
		,'undef'		: '?'
		,'pointer'		: '^'
		,'charpointer'	: '*'
	}
	var reverseEncodings = {}
	for (var e in encodings) reverseEncodings[encodings[e]] = e
	

	function	objc_unary_encoding(encoding)
	{
		// Structure arg
		if (encoding.indexOf(' ') != -1)
		{
			var structureName = encoding.split(' ')[1]
			var structureEncoding = JSCocoaFFIArgument.structureFullTypeEncodingFromStructureName(structureName)
			if (!structureEncoding)	throw 'no encoding found for structure ' + structureName

			//
			// Remove names of variables to keep only encodings
			//
			//	{_NSPoint="x"f"y"f}
			//	becomes
			//	{_NSPoint=ff}
			//
//			JSCocoaController.log('*' + structureEncoding + '*' + String(String(structureEncoding).replace(/"[^"]+"/gi, "")) + '*')
			return String(String(structureEncoding).replace(/"[^"]+"/gi, ""))
		}
		else
		{
			if (!(encoding in encodings))	
			{
				// Do we have a pointer to a class ?
				var match = encoding.match(/^(\w+)\s*\*$/)
				if (match)
				{
					var className = match[1]
					if (className in this && this[className]['class'] == this[className])	return '@'
				}
				throw	'invalid encoding : "' + encoding + '"'
			}
			return encodings[encoding]
		}
	}

	function	objc_encoding()
	{
		var encoding = objc_unary_encoding(arguments[0])
		encoding += '@:'
		
		for (var i=1; i<arguments.length; i++)	
			encoding += objc_unary_encoding(arguments[i])
		return	encoding
	}





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

		var newClass = JSCocoa.create({ 'class' : className, parentClass : parentClassName})
		for (var method in methods)
		{
			var isInstanceMethod = parentClass.instancesRespondToSelector(method)
			var isOverload = parentClass.respondsToSelector(method) || isInstanceMethod
//			JSCocoaController.log('adding method *' + method + '* to ' + className + ' isOverload=' + isOverload + ' isInstanceMethod=' + isInstanceMethod)
			
			if (isOverload)
			{
				var fn = methods[method]
				if (!fn || (typeof fn) != 'function')	throw '(overloading) Method ' + method + ' not a function'

				if (isInstanceMethod)	JSCocoa.overload({ instanceMethod : method, 'class' : newClass, jsFunction : fn })
				else					JSCocoa.overload({ classMethod : method, 'class' : newClass, jsFunction : fn })
			}
			else
			{
				// Extract encodings
				var encodings = methods[method]
				
				// IBOutlet
				if (encodings == 'IBOutlet')
				{
					class_add_outlet(newClass, method)
				}
				else
				// IBAction
				if (encodings.length == 2 && encodings[0] == 'IBAction' && (typeof encodings[1] == 'function'))
				{
					class_add_action(newClass, method, encodings[1])
				}
				else
				// Key
				if (encodings == 'Key')
				{
					class_add_key(newClass, method)
				}
				else
				// New method
				{
					if (typeof encodings != 'object' || !('length' in encodings))	throw 'Invalid definition of ' + method + ' in ' + inherit + ' ' + (typeof encodings) + ' ' + (encodings.length)

					// Extract method
					var fn = encodings.pop()
					if (!fn || (typeof fn) != 'function')	throw 'New method ' + method + ' not a function'
					
					var encoding = objc_encoding.apply(null, encodings)
					class_add_method(newClass, method, fn, encoding)
				}
			}
		}
		return	newClass
	}
	
	
	
	//
	//
	// Shared class methods : call these at runtime to add outlets, methods, actions to an existing class
	// 
	// 
	
	//
	// Outlets are set as properties starting with an underscore, to avoid recursive call in setProperty
	//
	function	class_add_outlet(newClass, name, setter)
	{
		var outletMethod = 'set' + name.substr(0, 1).toUpperCase() + name.substr(1) + ':'
		var encoding = objc_encoding('void', 'id')

		var fn = new Function('outlet', 'this.set({jsValue:outlet, forJsName : "_' + name + '"})')
		if (setter)	
		{
			if (typeof setter != 'function')	throw 'outlet setter not a function (' + setter + ')'
			fn = setter
		}
		JSCocoa.add({ instanceMethod : outletMethod, 'class' : newClass, jsFunction : fn, encoding : encoding })

		var fn = new Function('return this.JSValueForJSName("_' + name + '")')
		var encoding = objc_encoding('id')
		
		JSCocoa.add({ instanceMethod : name, 'class' : newClass, jsFunction : fn, encoding : encoding })					
	}
	
	//
	// Actions
	//
	function	class_add_action(newClass, name, fn)
	{
		if (name.charAt(name.length-1) != ':')	name += ':'
		var encoding = objc_encoding('void', 'id')
		JSCocoa.add({ instanceMethod : name, 'class' : newClass, jsFunction : fn, encoding : encoding })					
	}
	
	//
	// Keys : used in bindings and valueForKey — given keyName, creates two ObjC methods (getter/setter) - (id) keyName and - (void) setKeyName
	// 
	function	class_add_key(newClass, name, getter, setter)
	{
		// Get
		var fn = new Function('return this.JSValueForJSName("' + name + '")')
		if (getter)	
		{
			if (typeof getter != 'function')	throw 'key getter not a function (' + getter + ')'
			fn = getter
		}
		JSCocoa.add({ instanceMethod : name, 'class' : newClass, jsFunction : fn, encoding : objc_encoding('id') })

		// Set
		var setMethod = 'set' + name.substr(0, 1).toUpperCase() + name.substr(1) + ':'
		var fn = new Function('v', 'this.set({jsValue:v, forJsName : "' + name + '"})')
		if (setter)	
		{
			if (typeof setter != 'function')	throw 'key setter not a function (' + setter + ')'
			fn = setter
		}
		JSCocoa.add({ instanceMethod : setMethod, 'class' : newClass, jsFunction : fn, encoding : objc_encoding('void', 'id') })
	}
	
	//
	// Vanilla instance method add. Wrapper for JSCocoaController's addInstanceMethod
	// 
	function	class_add_method(newClass, name, fn, encoding)
	{
		JSCocoa.add({ instanceMethod : name, 'class' : newClass, jsFunction : fn, encoding : encoding })
	}
	
	//
	// Add raw javascript method
	//	__globalJSFunctionRepository__ holds [className][jsFunctionName] = fn
	if (!this.__globalJSFunctionRepository__)	var __globalJSFunctionRepository__ = {}
	function	class_add_js_function(newClass, name, fn)
	{
		var className = String(newClass)
		if (!__globalJSFunctionRepository__[className])	__globalJSFunctionRepository__[className] = {}
		__globalJSFunctionRepository__[className][name] = fn
	}

	
	
	//
	//
	//	Second kind of class definitions
	//	http://code.google.com/p/jscocoa/issues/detail?id=19
	//
	//
	
	// React on set
	function	class_set_definition(definition)
	{
		__classHelper__.methods = {}
		__classHelper__.outlets = {}
		__classHelper__.actions = {}
		__classHelper__.keys = {}
		__classHelper__.jsFunctions = {}
		definition()
		class_create_from_helper(__classHelper__)
	}
	function	class_create_from_helper(h)
	{
		var inherit = h.className
		var s = inherit.split('<')
		if (s.length != 2)	throw 'New class must specify parent class name'
		var className = s[0].replace(/ /gi, '')
		var parentClassName = s[1].replace(/ /gi, '')
		if (className.length == 0 || parentClassName.length == 0)	throw 'Invalid class definition : ' + inherit

		// Get parent class
		var parentClass = this[parentClassName]
		if (!parentClass)											throw 'Parent class ' + parentClassName + ' not found'
		var newClass = JSCocoa.create({ 'class' : className, parentClass : parentClassName})

		//
		// Overloaded and new methods
		//
		for (var method in h.methods)
		{
/*		
			if (h.methods[method].type == 'class method')
			{
				log('skipping class method ' + method)
				continue
			}
*/			
//			log('method.type=' + h.methods[method].type + ' ' + method)
			var isInstanceMethod = parentClass.instancesRespondToSelector(method)
//			var isInstanceMethod = h.methods[method].type == 'method'
			var isOverload = parentClass.respondsToSelector(method) || isInstanceMethod
//			JSCocoaController.log('adding method *' + method + '* to ' + className + ' isOverload=' + isOverload + ' isInstanceMethod=' + isInstanceMethod)
			
			if (isOverload)
			{
				var fn = h.methods[method].fn
				if (!fn || (typeof fn) != 'function')	throw 'Method ' + method + ' not a function'

				if (isInstanceMethod)	JSCocoa.overload({ instanceMethod : method, 'class' : newClass, jsFunction : fn })
				else					JSCocoa.overload({ classMethod : method, 'class' : newClass, jsFunction : fn })
			}
			else
			{
				// Extract method
				var fn = h.methods[method].fn
				if (!fn || (typeof fn) != 'function')	
				{
					log('*****' + method + '***' + fn)
					log('+++' + dumpHash(h.methods[method]))
					throw 'New method ' + method + ' not a function'
				}

//				log('encoding='  + encoding + ' class=' + newClass + ' method=' + method)
					
				var encodings = h.methods[method].encodingArray || h.methods[method].encoding.split(' ')
//				log('encodings=' + encodings)
				var encoding = objc_encoding.apply(null, encodings)
				class_add_method(newClass, method, fn, encoding)				
			}
		}
		
		//
		// Outlets
		//
		for (var outlet in h.outlets)
			class_add_outlet(newClass, outlet, h.outlets[outlet].setter)
			
		//
		// Actions
		//
		for (var action in h.actions)
			class_add_action(newClass, action, h.actions[action])

		//
		// Keys
		//
		for (var key in h.keys)
			class_add_key(newClass, key, h.keys[key].getter, h.keys[key].setter)

		//
		// JS Functions
		//
		for (var f in h.jsFunctions)
			class_add_js_function(newClass, f, h.jsFunctions[f])
	}
	function	class_set_encoding(encoding)
	{
		__classHelper__.methods[__classHelper__.name].encoding = encoding
		return	__classHelper__
	}
	function	class_set_encoding_array(encodingArray)
	{
		__classHelper__.methods[__classHelper__.name].encodingArray = encodingArray
		return	__classHelper__
	}
	function	class_set_function(fn)
	{
		// Method
		if (__classHelper__.type == 'method')				__classHelper__.methods[__classHelper__.name].fn = fn
		// Action
		else	if (__classHelper__.type == 'action')		__classHelper__.actions[__classHelper__.name] = fn
		// Function
		else	if (__classHelper__.type == 'jsFunction')	__classHelper__.jsFunctions[__classHelper__.name] = fn
	}

	function	class_set_setter(fn)
	{
		// Outlet
		if (__classHelper__.type == 'outlet')	__classHelper__.outlets[__classHelper__.name].setter = fn
		// Key
		else									__classHelper__.keys[__classHelper__.name].setter = fn
	}
	function	class_set_getter(fn)
	{
		__classHelper__.keys[__classHelper__.name].getter = fn
	}

	// Definition functions
	function	Class(name)
	{
		__classHelper__.className = name
		return	__classHelper__
	}
	function	Method(name)
	{
		__classHelper__.type 	= 'method'
		__classHelper__.name	= name
		__classHelper__.methods[__classHelper__.name] = { type : 'method' }
		return	__classHelper__
	}
	function	ClassMethod(name)
	{
		__classHelper__.type 	= 'method'
		__classHelper__.name	= name
		__classHelper__.methods[__classHelper__.name] = { type : 'class method' }
		return	__classHelper__
	}
	function	JSFunction(name)
	{
		__classHelper__.type 	= 'jsFunction'
		__classHelper__.name	= name
		return	__classHelper__
	}
	function	IBAction(name)
	{
		__classHelper__.type	= 'action'
		__classHelper__.name	= name
		return	__classHelper__
	}
	function	IBOutlet(name)
	{
		__classHelper__.type	= 'outlet'
		__classHelper__.name	= name
		__classHelper__.outlets[name] = {}
		return	__classHelper__
	}
	function	Key(name)
	{
		__classHelper__.type	= 'key'
		__classHelper__.name	= name
		if (!__classHelper__.keys[name])	__classHelper__.keys[name] = {}
		return	__classHelper__
	}


	// Shadow object collecting class definition data
	var __classHelper__ = { encoding : class_set_encoding, encodingArray : class_set_encoding_array }
	__classHelper__.__defineSetter__('definition',	class_set_definition)
	__classHelper__.__defineSetter__('fn', 			class_set_function)
	__classHelper__.__defineSetter__('getter',		class_set_getter)
	__classHelper__.__defineSetter__('setter',		class_set_setter)
	
	
	// Running ObjC GC ?
	var hasObjCGC = false
	if (('NSGarbageCollector' in this) && !!NSGarbageCollector.defaultCollector) hasObjCGC = true
	
	
	function	loadFramework(name)
	{
		__jsc__.loadFrameworkWithName(name)
	}
	
	
	//
	// Describe struct
	//
	function	describeStruct(o, level)
	{
		if (level == undefined)	level = 0
		// Bail if structure contains a cycle
		if (level > 100)		return ''
		
		var str = ''
		
		if (typeof(o) == 'object' || typeof(o) == 'function')
		{
			str += '{'
			var elements = []
			for (var i in o)
				elements.push(i + ':' + describeStruct(o[i], level+1))
			str += elements.join(', ')
			str += '}'
		}
		else
			str += o

		return	str
	}
	

	//
	// type o
	//
	function	outArgument()
	{
		var o = JSCocoaOutArgument.instance()
		if (arguments.length == 2)	o.mateWith({ memoryBuffer : arguments[0], atIndex : arguments[1] })
		return	o
	}
	
	function	memoryBuffer(types)
	{
//		return	JSCocoaMemoryBuffer.instance()
		return	JSCocoaMemoryBuffer.instance({ withTypes : types })
	}


	//
	// Dump the call stack with arguments.calle.caller (Called from JSCocoa)
	//	
	//	Eric Wendelin's Javascript stacktrace in any browser
	//	http://eriwen.com/javascript/js-stack-trace/
	//
	function	dumpCallStack()
	{
		var maxDumpDepth = 100
		var dumpDepth = 0
		var caller = arguments.callee.caller
		// Skip ourselves
		caller = caller.caller

		// Build call stack
		var stack = []
		while (caller && dumpDepth < maxDumpDepth)
		{
			var fn = caller.toString()
			var fname = fn.substring(fn.indexOf("function") + 9, fn.indexOf("(")) || "anonymous";
			var str = fname
			if (caller.arguments.length)
			{
				str += ' ('
				for (var i=0; i<caller.arguments.length; i++)	
				{
					str += caller.arguments[i]
					if (i < caller.arguments.length-1)
						str += ', '
				}
				str += ')'
			}
//			if (caller.arguments.length) str += caller.arguments.join(',')
			stack.push(str)
			dumpDepth++
			caller = caller.caller
		}
		
		// Dump call stack
		var str = ''
		for (var i=0; i<stack.length; i++)
			str += '(' + (stack.length-i) + ') ' + stack[i] + '\n'
		return str
	}
	
	
	//
	// expandJSMacros
	//	convert ObjC-like class syntax to Javascript
	//
	function	expandJSMacros(script)
	{
		if (script.match(/^\s*class\s+\w+\s+<\s+\w+\s*$/m))
		{
			// Replace classes (m modifier to treat as multiple lines)
			script = script.replace(/^\s*(class)\s+(\w+)\s+(<)\s+(\w+)\s*$/gm, 'Class(\'$2 < $4\').definition = function ()')
			// Replace methods
			script = script.replace(/^\s*(\-|\+)\s\(.*$/gm, expandJSMacros_ReplaceMethods)
			
			// Replace outlets
			script = script.replace(/^\s*IBOutlet\s+(\w+)/gm, function (r) { dumpHash('***' + r); return '+++' + r[1] } )
			
			// Replace actions
			
			log('****************')
			log('\n' + script)
			log('****************')
		}
		return	script
	}
	function	expandJSMacros_ReplaceMethods(r)
	{
		var name
		var type
		var args = []
		var names = []

		// Parse method
		var s = String(r)
		// extract class or instance method marker
		s = s.replace(/(\+|\-)/, function (r) { type = r == '-' ? 'Method' : 'ClassMethod'; return '' } )
		// extract arguments
		s = s.replace(/\([^)]+\)/g, function (r) { r = String(r); r= r.substr(1, r.length-2); args.push(r); return '' } )
		// extract argument names
		s = s.replace(/\w+(\s|$)/gm, function (r) { names.push(r.replace(/\s/g, '')); return '' } )
		// extract method name
		var name = s.replace(/\s/g, '')
		
		// fixup : if no name and one argument, we have a zero arg method
		if (args.length == 1 && names.length == 1) name = names[0], names = []
		
		// Bail if no return value
		if (args.length < 1)	throw 'Need at least one return value in ' + r
		
//		log('name=*' + name + '* type=' + type + ' args=' + args + ' names=' + names)
		
		

//		log('(2) s=' + s)
//		var r = 
//		log(r.replace(/\([^)]+\)/g, ''))
/*		
		var parts0 = r.split('(')
		var parts1 = []
		var parts2 = []
		parts0.forEach(function (part) { parts.push(part.split(')')) } )
		log(parts)
*/		
//		var idx = r.indexOf('(')
//		while (idx != -1)
		{
		}
var str = ''
		var encoding = args.map(function (r) { return "'" + r + "'" })
		var str = type + "('" + name + "').encodingArray([" + encoding + "]).fn = function (" + names.join(', ') + ")"
		return str
	}
	
	function	expandJSMacros_ReplaceOutlets(r)
	{
		
	}

