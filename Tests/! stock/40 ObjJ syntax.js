

	//
	// Objective-J, JSTalk - like syntax
	//	Use a preprocessor to convert ObjC-like messaging to Javascript functions
	//

	class ObjJTest < NSObject
	{
		+ (int)noParamClassMethod
		{
			return 42
		}
		- (int)noParamInstanceMethod
		{
			return 1312
		}
		+ (int)oneParamClassMethod:(int)a
		{
			return a*2
		}
		- (int)oneParamInstanceMethod:(int)a
		{
			return a*3
		}
		+ (int)addOne:(int)one andTwo:(int)two
		{
			return one + two
		}
		- (int)multiplyOne:(int)one andTwo:(int)two
		{
			return one * two
		}
		
		- (double)wantInt:(int)a andNSArray:(NSArray*)array andFloat:(float)b
		{
			if (![array[0] isKindOfClass:NSNumber])				throw 'ObjJ syntax failed (9)'
			if (![array[1] isKindOfClass:NSString])				throw 'ObjJ syntax failed (10)'
			// Two different kinds of test
			if (![array[2] isKindOfClass:NSArray])				throw 'ObjJ syntax failed (11)'
			if (![[array[3] class] == [NSMutableArray class]])	throw 'ObjJ syntax failed (12)'
			
			// Play a bit with objecAtIndex
			if ([[array[2] objectAtIndex:0] intValue] != 1)		throw 'ObjJ syntax failed (13)'
			if ([[array[2] objectAtIndex:1] intValue] != 2)		throw 'ObjJ syntax failed (14)'
			if ([[array[2] objectAtIndex:2] intValue] != 3)		throw 'ObjJ syntax failed (15)'

			if ([[array objectAtIndex:3][0] intValue] != 4)		throw 'ObjJ syntax failed (16)'
			if ([[array objectAtIndex:3][1] intValue] != 5)		throw 'ObjJ syntax failed (17)'
			if ([[array objectAtIndex:3][2] intValue] != 6)		throw 'ObjJ syntax failed (18)'

			if ([array[2][0] intValue] != [[array objectAtIndex:2] objectAtIndex:0])		throw 'ObjJ syntax failed (19)'
			
//			if ([array[1] class])
			return a+b
		}
		
		- (IBAction)doThis:(id)sender
		{
			savedSender = sender
		}
		
		// Test auto get/set
		IBOutlet myOutlet
		// Test custom get
		IBOutlet myOutlet2
		// Test custom set
		IBOutlet myOutlet3
		// Test custom get/set
		IBOutlet myOutlet4

		- (id)myOutlet2
		{
			wentThrough = true
			return this._myOutlet2
		}
		
		- (void)setMyOutlet3:(id)outlet
		{
			wentThrough = true
			this._myOutlet3 = outlet
		}
		
		- (void)setMyOutlet4:(id)outlet
		{
			wentThrough = true
			this._myOutlet4 = outlet
		}
		- (id)myOutlet4
		{
			wentThrough = true
			return this._myOutlet4
		}
	}
	


	if ([NSWorkspace sharedWorkspace] != NSWorkspace.sharedWorkspace)	throw 'ObjJ syntax failed (1)'
	
	var o = ObjJTest.instance
	
	if ([ObjJTest noParamClassMethod] != 42)							throw 'ObjJ syntax failed (2)'
	if ([o noParamInstanceMethod] != 1312)								throw 'ObjJ syntax failed (3)'
	if ([ObjJTest oneParamClassMethod:37] != 37*2)						throw 'ObjJ syntax failed (4)'
	if ([o oneParamInstanceMethod:875] != 875*3)						throw 'ObjJ syntax failed (5)'
	if ([ObjJTest addOne:786 andTwo:5487] != 786+5487)					throw 'ObjJ syntax failed (6)'
	if ([o multiplyOne:3721 andTwo:94] != 3721*94)						throw 'ObjJ syntax failed (7)'
	
	// As class is a reserved word, the preprocessor must bracket it.
	// o.class -> o['class']
	if ([o class] != o['class'])										throw 'ObjJ syntax failed (class)'
	
	var r = [o wantInt:7 andNSArray:[[NSNumber numberWithDouble:1.23], [NSString stringWithString:'hello'], [NSArray arrayWithObjects:1, 2, 3], [4, 5, 6]] andFloat:8]
	if (r != 7+8)														throw 'ObjJ syntax failed (8)'
	
	// Test IBAction
	var savedSender = nil
	[o doThis:'hello']
	if (savedSender != 'hello')											throw 'ObjJ syntax failed (9)'
	savedSender = nil
	
	// Test IBOutlet
	var p = 'hello'
	[o setMyOutlet:p]
	if ([o myOutlet]!= p)												throw 'ObjJ syntax failed (11)'

	var p = 'hello2'
	var wentThrough = false
	[o setMyOutlet2:p]
	if ([o myOutlet2]!= p)												throw 'ObjJ syntax failed (12)'
	if (!wentThrough)													throw 'ObjJ syntax failed (13)'

	var p = 'hello3'
	var wentThrough = false
	[o setMyOutlet3:p]
	if (!wentThrough)													throw 'ObjJ syntax failed (14)'
	if ([o myOutlet3]!= p)												throw 'ObjJ syntax failed (15)'

	var p = 'hello4'
	var wentThrough = false
	[o setMyOutlet4:p]
	if (!wentThrough)													throw 'ObjJ syntax failed (16)'
	var wentThrough = false
	if ([o myOutlet4]!= p)												throw 'ObjJ syntax failed (17)'


	o = null
	
	