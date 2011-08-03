

	//
	// Use ƒ (Option-f) as a shortcurt for function. Can omit name and arguments
	//


	// name + parameters
	// function name(a, b) { ... }
	ƒ nameAndParams(a, b)
	{
		return a+b
	}
	
	// name
	// function name() { ... }
	ƒ name
	{
		return 'hello'
	}
	
	// params
	// function (a, b) { ... }
	var f2 = ƒ (a, b)
	{
		return a*b
	}
	
	// no name, no params
	var f3 = ƒ
	{
		return 'world'
	}
	

	// function () { ... }
	var f1 = ƒ{ return 'hello' }


	function	DualNumber(a, b)
	{
		this.a = a
		this.b = b
	}
	DualNumber.prototype.toString = function ()
	{
		return '(' + this.a + ':' + this.b + ')'
	}
	var a = [new DualNumber(5, 2), new DualNumber(1, 3), new DualNumber(8, 1), new DualNumber(1, 1)]
//	log('raw=' + a)
	a.sort(ƒ{
				var a = arguments[0]
				var b = arguments[1]
				if (a.a < b.a)	return -1
				if (a.a > b.a)	return 1
				if (a.b < b.b)	return -1
				if (a.b > b.b)	return 1
				return	0
			})
			
//	log('sorted=' + a)
	
	if (nameAndParams(8, 5) != 13)		throw 'ƒ shortcut failed (1)'
	if (name() != 'hello')				throw 'ƒ shortcut failed (2)'
	if (f2(9, 6) != 54)					throw 'ƒ shortcut failed (3)'
	if (f3() != 'world')				throw 'ƒ shortcut failed (4)'
	
	var sorted =	a[0].a == 1 && a[0].b == 1
				&&	a[1].a == 1 && a[1].b == 3
				&&	a[2].a == 5 && a[2].b == 2
				&&	a[3].a == 8 && a[3].b == 1
				
	if (!sorted)						throw 'ƒ shortcut failed (5)'
				
				