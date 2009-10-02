
	//
	// Swizzle ! replace existing method implementations of any class with ours.
	//	Call this.Original(arguments) to call original method.
	//

	// Split call disabled by default since ObjJ syntax
	var useSplitCall = __jsc__.useSplitCall
	__jsc__.useSplitCall = true

	// Test class
	class ObjCClassTestSwizzle < NSObject
	{
		- (int)addX:(int)x andY:(int)y
		{
			return x + y
		}
		
		+ (float)addFloatX:(float)x andFloatY:(float)y
		{
			return x + y
		}
/*
		- (int)addX:(int)x andY:(int)y andZ:(int)z
		{
			return x + y + z
		}
*/		
	}
	
	// Adding methods
	class ObjCClassTestSwizzle
	{
		- (int)add13:(int)a
		{
			return a + 13
		}
		- (NSString*)addPrefix:(NSString*)prefix andSuffix:(NSString*)suffix toString:(NSString*)string
		{
			return prefix + string + suffix
		}
	}
	
	// Swizzle !
	class ObjCClassTestSwizzle
	{
/*
		Swizzle- (int)addX:(int)x andY:(int)y andZ:(int)z
		{
			log('args(' + arguments.length + ') x=' + x + ' y=' + y + ' z=' + z)
			log('=>SUM=' + (x+y+z))
			var r = this.Original(arguments)
			swizzleInstanceCalled = true
//			if (x != arg1)	throw	'swizzle : wrong argument for x — expected ' + arg1 + ', got ' + x + ' (1)'
//			if (y != arg2)	throw	'swizzle : wrong argument for x — expected ' + arg2 + ', got ' + y + ' (2)'
			log('x=' + x + ' y=' + y + ' z=' + z)
			return	r
		}
*/
		Swizzle- (int)addX:(int)x andY:(int)y
		{
			var r = this.Original(arguments)
			swizzleInstanceCalled = true
			if (x != arg1)	throw	'swizzle : wrong argument for x — expected ' + arg1 + ', got ' + x + ' (1)'
			if (y != arg2)	throw	'swizzle : wrong argument for x — expected ' + arg2 + ', got ' + y + ' (2)'
			return	r
		}
		
		Swizzle+ (float)addFloatX:(float)x andFloatY:(float)y
		{
			var r = this.Original(arguments)
			swizzleClassCalled = true
			if (x != arg1)	throw	'swizzle : wrong argument for x — expected ' + arg1 + ', got ' + x + ' (3)'
			if (y != arg2)	throw	'swizzle : wrong argument for x — expected ' + arg2 + ', got ' + y + ' (4)'
			return	r
		}
	}


	// Test extra methods
	var o1 = ObjCClassTestSwizzle.instance
	var r = o1.add13(2)
	if (r != 15)				throw 'swizzle : add method failed (1)'
	
	var r = o1.add({ prefix : 'hello', andSuffix : 'world', toString : 'BIG' })
	if (r != 'helloBIGworld')	throw 'swizzle : add method failed (2)'
	
	// Test swizzled methods
	var	swizzleInstanceCalled	= false
	var swizzleClassCalled		= false

	var arg1 = 3
	var arg2 = 5
	var r = o1.add({ x : arg1, andY : arg2 })
	if (!swizzleInstanceCalled)	throw 'swizzle : instance call failed (1)'
	if (r != 8)					throw 'swizzle : instance call failed (2)'

	var arg1 = 3.5
	var arg2 = 5.5
	var r = ObjCClassTestSwizzle.add({ floatX : arg1, andFloatY : arg2 })
	if (!swizzleClassCalled)	throw 'swizzle : class call failed (1)'
	if (r != 9)					throw 'swizzle : class call failed (2)'

	o1 = null

	__jsc__.useSplitCall = useSplitCall
