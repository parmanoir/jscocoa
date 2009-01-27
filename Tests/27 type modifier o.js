

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

//	throw	"type modifier 'o' failed for function"
	
	var rect = new NSRect(10, 20, 30, 40)
	var rect1 = new outArgument
	var rect2 = new outArgument
	NSDivideRect(rect, rect1, rect2, 5, NSMinXEdge);


//	[NSScanner scanDecimal:]
//	[NSFileManager fileExistsAtPath:isDirectory:}
	
	
	major = null
	minor = null
	windowCount = null
	rect1 = null
	rect2 = null