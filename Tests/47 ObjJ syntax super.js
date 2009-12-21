

	//
	// Objective-J, JSTalk - like syntax
	//	super addon
	//
	/*
		- (void)myMethod:(id)arg
		{
			// Standard argument, gotten trough arguments.callee
			this.Super(arguments)
			
			// ObjC like call
			[super myMethod:arg]
			// Translates to
			this.Super(arguments, 'myMethod')
			
			// Same for swizzling	
			[original myMethod:arg]
			// ->
			this.Original(arguments, 'myMethod')
		}
	*/


	var wentThrough1 = false
	var wentThrough2 = false
	var wentThrough3 = false
	var wentThrough4 = false

	//
	// Super test
	//
	class ObjJSuperTest1 < NSObject
	{
		- (int)method1:(int)a and2:(int)b
		{
			wentThrough1 = true
			return a+b+1
		}
	}
	
	class ObjJSuperTest2 < ObjJSuperTest1
	{
		- (int)superTestWith:(int)a and:(int)b
		{
			return [super method1:a and2:b]
		}

		- (int)method1:(int)a and2:(int)b
		{
			wentThrough2 = true
			return a + b + [super method1:a and2:b] + 10			
		}
	}


	var o = [ObjJSuperTest2 instance]
	
	wentThrough1 = wentThrough2 = false
	var r = [o superTestWith:4 and:3]
	if (r != (4+3+1))					throw 'ObjJ super syntax failed (1)'
	if (!wentThrough1 || wentThrough2)	throw 'ObjJ super syntax failed (2)'

	wentThrough1 = wentThrough2 = false
	var r = [o method1:10 and2:5]
	if (r != (10+5+1+10+5+10))			throw 'ObjJ super syntax failed (3)'
	if (!wentThrough1 || !wentThrough2)	throw 'ObjJ super syntax failed (4)'


	//
	// Swizzle test
	//
	class ObjJSuperTest3 < NSObject
	{
		- (int)addThis:(int)a andThat:(int)b
		{
			wentThrough3 = true
			return a + b + 100
		}
	}
	
	class ObjJSuperTest3
	{
		swizzle - (int)addThis:(int)a andThat:(int)b
		{
			wentThrough4 = true
			return [original addThis:a andThat:b] + 1000
		}
	}
	
	var o = [ObjJSuperTest3 instance]
	var r = [o addThis:11 andThat:2]
	if (r != (11+2+100+1000))			throw 'ObjJ super syntax failed (5)'
	if (!wentThrough3 || !wentThrough4)	throw 'ObjJ super syntax failed (6)'
	
	
	o = null



