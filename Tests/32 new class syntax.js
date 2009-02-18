	//
	// new class syntax
	//

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
		
		IBOutlet outlet1
		
		IBOutlet outlet2 (newValue)
		{
			passedOutlet2 = true
		}

		IBAction clickMe
		{
			this.passedAction1 = sender
		}
		
		IBAction clickMeToo(notifier)
		{
			this.passedAction2 = notifier
		}
		
		- (NSRect)addRect:(NSRect)rect1 andRect:(NSRect)rect2
		{
			return	new NSRect(	 rect1.origin.x+rect2.origin.x
								,rect1.origin.y+rect2.origin.y
								,rect1.size.width+rect2.size.width
								,rect1.size.height+rect2.size.height)
		}
		
		- (void)methodWithRect:(NSRect)rect
		{
		}		
	}

	// Test derivation from custom clas
	class ObjCClassTest2 < ObjCClassTest
	{
		// check super
		- (int)addX:(int)x andY:(int)y
		{
			passedAdd2 = true
			return this.Super(arguments)
		}
	}
	
	
	// Test add
	var o1 = ObjCClassTest.instance()
	
	var r = o1.add({ x : 3, andY : 5 })
	if (r != 8)			throw 'new class syntax : add failed (1)'
	
	// Test derived add
	var o2 = ObjCClassTest2.instance()

	var passedAdd2 = false
	var r = o2.add({ x : 3, andY : 5 })
	if (!passedAdd2)	throw 'new class syntax : add failed (2)'
	if (r != 8)			throw 'new class syntax : add failed (3)'
	
	// Test outlets
	var obj = NSWorkspace.sharedWorkspace
	o1['setOutlet1:'](obj)
	if (o1.outlet1 != NSWorkspace.sharedWorkspace)			throw 'new class syntax : outlet failed (1)'
	
	var passedOutlet2 = false
	o1['setOutlet2:'](obj)
	if (!passedOutlet2)										throw 'new class syntax : outlet failed (2)'
	
	// Test actions
	o1.clickMe(obj)
	if (o1.passedAction1 != NSWorkspace.sharedWorkspace)	throw 'new class syntax : action failed (1)'

	o1.clickMeToo(obj)
	if (o1.passedAction2 != NSWorkspace.sharedWorkspace)	throw 'new class syntax : action failed (2)'
	

	// Test structures
	NSMakeRect(5, 6, 7, 8)
	NSMakeRect(1, 2, 3, 4), NSMakeRect(5, 6, 7, 8)
	var r = o1.add({ rect : NSMakeRect(1, 2, 3, 4), andRect: NSMakeRect(5, 6, 7, 8) })
	if (r.origin.x != 6)		throw 'new class syntax : struct failed (1)'
	if (r.origin.y != 8)		throw 'new class syntax : struct failed (2)'
	if (r.size.width != 10)		throw 'new class syntax : struct failed (3)'
	if (r.size.height != 12)	throw 'new class syntax : struct failed (4)'

	// Test equality of method signatures NSView drawRect
	var s1 = __jsc__.typeEncodingOfMethod_class('drawRect:', 'NSView').replace(/[0-9]/g, '')
	var s2 = __jsc__.typeEncodingOfMethod_class('methodWithRect:', 'ObjCClassTest')
	if (s1 != s2)				throw 'new class syntax : method signatures not equal'



	
//	o.hi
	
//	ObjCClassTest.hello
	
	o1 = null
	o2 = null
	obj = null
	
//- (void)drawRect:(NSRect)rect
//	test w/ 
//	- (const char*)typeEncodingOfMethod:(NSString*)methodName class:(NSString*)className
