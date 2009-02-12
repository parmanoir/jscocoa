
/*

Re: NSColor to CGColor by j o a r
http://www.cocoabuilder.com/archive/message/cocoa/2006/11/12/174339


static CGColorRef CGColorCreateFromNSColor (CGColorSpaceRef  
colorSpace, NSColor *color)

   NSColor *deviceColor = [color colorUsingColorSpaceName:  
NSDeviceRGBColorSpace];

   float components[4];
   [deviceColor getRed: &components[0] green: &components[1] blue:  
&components[2] alpha: &components[3]];

   return CGColorCreate (colorSpace, components);

*/

	function	floatsEq(a, b)
	{
		if (Math.abs(a-b) < 0.001)	return	true
		return	false
	}


	//
	// Test get : allocate a memory buffer and have Cocoa fill it
	//
	var buffer = new memoryBuffer('ffff')

	var r = 0.9
	var g = 0.8
	var b = 0.7
	var a = 0.6

	var color = NSColor.colorWithDevice({ red : r, green : g, blue : b, alpha : a })
	
	// Use scrambled pattern 2 3 0 1 instead of 0 1 2 3 to test
	color.get({	red : new outArgument(buffer, 2), 
				green : new outArgument(buffer, 3), 
				blue : new outArgument(buffer, 0),
				alpha : new outArgument(buffer, 1) })

/*				
	log('color=' + color)
	log('buffer[0]=' + buffer[0])
	log('buffer[1]=' + buffer[1])
	log('buffer[2]=' + buffer[2])
	log('buffer[3]=' + buffer[3])
*/
	if (!floatsEq(buffer[2], r))	throw 'pointer handling get failed (1)'
	if (!floatsEq(buffer[3], g))	throw 'pointer handling get failed (2)'
	if (!floatsEq(buffer[0], b))	throw 'pointer handling get failed (3)'
	if (!floatsEq(buffer[1], a))	throw 'pointer handling get failed (4)'

	//
	// Test set with the same buffer
	//
	var a = 123.456
	var b = -87.6
	var c = 563.1
	var d = -1.1
	buffer[0] = a
	buffer[1] = b
	buffer[2] = c
	buffer[3] = d
	
	if (!floatsEq(buffer[0], a))	throw 'pointer handling set failed (5)'
	if (!floatsEq(buffer[1], b))	throw 'pointer handling set failed (6)'
	if (!floatsEq(buffer[2], c))	throw 'pointer handling set failed (7)'
	if (!floatsEq(buffer[3], d))	throw 'pointer handling set failed (8)'

	
	buffer = null
	
	//
	// Test raw buffer
	//
/*
	var buffer = new memoryBuffer('cccccc')
	buffer[0] = 'h'
	buffer[1] = 'e'
	buffer[2] = 0
	
	var str = NSString.stringWithUTF8String(buffer)
	log('str=' + str)
	
	if (str != 'hello')				throw 'pointer handling raw buffer failed (9)'
*/

	var buffer = new memoryBuffer('fff')
	
	var path = NSBezierPath.bezierPath
	path.moveToPoint(new NSPoint(0, 0))
	path.curve({ toPoint : new NSPoint(10, 20), controlPoint1 : new NSPoint(30, 40), controlPoint2 : new NSPoint(50, 60) })
	
	log(path.elementCount)
	log(path.elementAtIndex(0))
	
	buffer = null
	
	
/*
- (NSBezierPathElement)elementAtIndex:(NSInteger)index
		     associatedPoints:(NSPointArray)points;
// As above with points == NULL.
- (NSBezierPathElement)elementAtIndex:(NSInteger)index;
- (void)setAssociatedPoints:(NSPointArray)points atIndex:(NSInteger)index;



NSClassFromString	
*/
/*

	throw '29 pointer'

//NSString
//Check stringWithUTF8String vec 'hello' \0
	throw 'check raw points bezier path'
	throw 'someFunction(memoryBuffer)'
	
	throw 'buffer[0] = ...'

	log(buffer[0])
	buffer[0] = 4

elementAtIndex:associatedPoints


*/	
