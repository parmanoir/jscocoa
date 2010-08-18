
	//
	// JS functions defined within a class definition become part of that class
	//
	
	
	class ObjCClassInnerJSFunctionTest < NSObject
	{
		- (id)init
		{
			var o = this.Super(arguments)
			return o
		}
		// Standard ObjC instance method
		- (int)addOne:(int)one andTwo:(int)two
		{
			return one + two
		}
		// Raw Javascript instance method 
		function add(one, two)
		{
			return one + two
		}

		- (int)multiplyOne:(int)one andTwo:(int)two
		{
			return one * two
		}
		function multiply(one, two)
		{
			return one * two
		}
	}
	
	var o = ObjCClassInnerJSFunctionTest.instance
	
	var r1 = [o addOne:5 andTwo:8]
	if (r1 != 13)	throw 'class inner js functions failed (1)'
	var r2 = o.add(5, 8)
	if (r2 != 13)	throw 'class inner js functions failed (2)'

	var r1 = [o multiplyOne:5 andTwo:8]
	if (r1 != 40)	throw 'class inner js functions failed (3)'
	var r2 = o.multiply(5, 8)
	if (r2 != 40)	throw 'class inner js functions failed (4)'
	
	
	o = null
	
	
	