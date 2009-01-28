

/*

	type o arguments (as named by the ObjC runtime)
	Given pointers to arguments, a function can write multiple return values to them.

	// Return OpenGL version
	int major, minor;
	NSOpenGLGetVersion(&major, &minor);
	
	// JSCocoa eq
	var major = new outArgument
	var minor = new outArgument
	NSOpenGLGetVersion(major, minor)
	log('major=' + major + ' minor=' + minor)

*/


	//
	// Test basic type encoding (int)
	//
	var major = new outArgument
	var minor = new outArgument
	NSOpenGLGetVersion(major, minor)
	
	if (typeof (major.valueOf()) != 'number')	throw 'type o failed (1)'
	if (typeof (minor.valueOf()) != 'number')	throw 'type o failed (2)'
	if (!(major >= 1))							throw 'type o failed (3)'
	
//	log('major=' + major + ' minor=' + minor)


	var windowCount = new outArgument
	NSCountWindows(windowCount)
//	log('windowCount=' + windowCount)
	
	if (typeof (minor.valueOf()) != 'number')	throw 'type o failed (4)'
	if (!(major >= 1))							throw 'type o failed (5)'

	
	//
	// Test structs
	//
	var rect = new NSRect(10, 20, 30, 40)

	var rect1 = new outArgument
	var rect2 = new outArgument
	NSDivideRect(rect, rect1, rect2, 5, NSMinXEdge);

	if (rect1.origin.x != 10 || rect1.origin.y != 20 || rect1.size.width != 5 || rect1.size.height != 40)	throw 'type o failed (6)'
	if (rect2.origin.x != 15 || rect2.origin.y != 20 || rect2.size.width != 25 || rect2.size.height != 40)	throw 'type o failed (7)'



	//
	// Test ObjC call
	//

//	[NSScanner scanDecimal:]
//	[NSFileManager fileExistsAtPath:isDirectory:}
	
	
	major = null
	minor = null
	windowCount = null
	rect1 = null
	rect2 = null
