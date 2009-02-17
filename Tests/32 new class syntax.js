	// new class syntax
	class ObjCClassTest < NSObject
	{
		- (int)addX:(int)x andY:(int)y
		{
			return x + y
		}
		
		- (NSString*)hi
		{
			log(this)
			return	'lk'
		}
		+ (NSString*)hello
		{
			log(this)
			return 'hello'
		}
		
		IBOutlet blah
		
		IBOutlet blah2 (newValue)
		{
		)

		IBAction clickMeToo
		{
		}
		
		IBAction clickMe (sender)
		{
		}
		
		
	}

	class ObjCClassTest2 < ObjCClassTest
	{
		// check super
	}
	
	
	var o = ObjCClassTest.instance()
	
	var r = o.add({ x : 3, andY : 5 })
	log(r)
	
//	o.hi
	
	ObjCClassTest.hello
	
//- (void)drawRect:(NSRect)rect
//	test w/ 
//	- (const char*)typeEncodingOfMethod:(NSString*)methodName class:(NSString*)className
