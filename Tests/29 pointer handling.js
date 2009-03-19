
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
	var path = NSBezierPath.bezierPath
	path.moveToPoint(new NSPoint(0, 0))
	path.curve({ toPoint : new NSPoint(10, 20), controlPoint1 : new NSPoint(30, 40), controlPoint2 : new NSPoint(50, 60) })
	
	
	// Allocate room for 3 points
	var buffer = new memoryBuffer('ffffff')
	// Copy points into our buffer
	path.element({ atIndex : 1, associatedPoints : new outArgument(buffer, 0) })

	// Check points were copied OK (controlPoint1, controlPoint2, toPoint)
	if (!floatsEq(buffer[0], 30))	throw 'pointer handling raw get failed (9)'
	if (!floatsEq(buffer[1], 40))	throw 'pointer handling raw get failed (10)'
	if (!floatsEq(buffer[2], 50))	throw 'pointer handling raw get failed (11)'
	if (!floatsEq(buffer[3], 60))	throw 'pointer handling raw get failed (12)'
	if (!floatsEq(buffer[4], 10))	throw 'pointer handling raw get failed (13)'
	if (!floatsEq(buffer[5], 20))	throw 'pointer handling raw get failed (14)'

/*
	log(buffer[0])
	log(buffer[1])
	log(buffer[2])
	log(buffer[3])
	log(buffer[4])
	log(buffer[5])
*/

	// Change point values
	buffer[0] = 123
	buffer[1] = 456
	buffer[2] = 789
	buffer[3] = 0.123
	buffer[4] = 0.456
	buffer[5] = 0.789
	
	path.set({ associatedPoints : buffer, atIndex : 1 })
	// Overwrite existing points
	path.setAssociatedPoints_atIndex(buffer, 1)

	// Copy points into a new buffer
	var buffer2 = new memoryBuffer('ffffff')
	path.element({ atIndex : 1, associatedPoints : new outArgument(buffer2, 0) })

	if (!floatsEq(buffer2[0], 123))		throw 'pointer handling raw get failed (15)'
	if (!floatsEq(buffer2[1], 456))		throw 'pointer handling raw get failed (16)'
	if (!floatsEq(buffer2[2], 789))		throw 'pointer handling raw get failed (17)'
	if (!floatsEq(buffer2[3], 0.123))	throw 'pointer handling raw get failed (18)'
	if (!floatsEq(buffer2[4], 0.456))	throw 'pointer handling raw get failed (19)'
	if (!floatsEq(buffer2[5], 0.789))	throw 'pointer handling raw get failed (20)'


	buffer = null
	buffer2 = null


