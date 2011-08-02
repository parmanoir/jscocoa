
	/*
	
		One-line Ruby-like 
			return if ...
			return unless ...
			
			
		return something if (condition)
		-> transformed to
		if (condition) return something

		return something unless (condition)
		-> transformed to
		if (!(condition)) return something	
		
	*/
	
	function	returnIf1(param)
	{
		return 'noparam' if (!param)
	}
	
	function	returnIf2(param)
	{
		return 'wantOdd' unless(param&1)
		return 'isOdd'
	}
	
	function	returnIf3(a, b)
	{
		return function (a, b) { return a+b }(a, b) if (a > 10)
		return function (a, b) { return a*b }(a, b) if (a <= 10 && b < 5)
	}
	
	
	var r1 = returnIf1()
	if (r1 != 'noparam')	throw 'return if failed (1)'
	
	var r2 = returnIf2(4)
	if (r2 != 'wantOdd')	throw 'return if failed (2)'
	
	var r3 = returnIf3(20, 5)
	if (r3 != 25)			throw 'return if failed (3)'
	var r3 = returnIf3(7, 3)
	if (r3 != 21)			throw 'return if failed (4)'
	