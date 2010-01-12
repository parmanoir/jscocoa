

	//
	// Write something at some address
	//	In particular, return an NSError in a method
	//

	@implementation NSErrorCallback : NSObject
	
		- (BOOL)someMethodReturningAnError:(NSError**)outError
		{
			var b = new memoryBuffer('^')
			b[0] = outError

			[b referenceObject:error usingPointerAtIndex:0]
			var errorReadBack = [b dereferenceObjectAtIndex:0]

			if (errorReadBack != error)					throw 'NSError** read/write failed'
			return	res
		}
	
	@end
	
	var o = [NSErrorCallback instance]
	
	
	var res = true
	
	var errorDomain	= 'NSErrorCallback test'
	var errorCode	= '503'
	var error		= [NSError errorWithDomain:errorDomain code:errorCode userInfo:nil]
	
	var delegate = NSApplication.sharedApplication.delegate
	
	// Call ourselves back
	var b = [delegate callbackNSErrorWithClass:o]
	
	var errorFromDelegate = [delegate testNSError]
	if (errorFromDelegate.domain != errorDomain)	throw 'NSError** failed (1)'
	if (errorFromDelegate.code != errorCode)		throw 'NSError** failed (2)'


	// Test again, this time with an error from a file read
	var url = [NSURL fileURLWithPath:@"/non/existent"];
	var error = new outArgument
	var r = [@"hello" writeToURL:url atomically:NO encoding:NSUTF8StringEncoding error:error];
	error = error.outValue

	if (error == null)								throw 'Expected an error while writing to a non existent file'

	errorDomain = error.domain
	errorCode	= error.code
	
	var b = [delegate callbackNSErrorWithClass:o]
	
	var errorFromDelegate = [delegate testNSError]
	if (errorFromDelegate.domain != errorDomain)	throw 'NSError** failed (3)'
	if (errorFromDelegate.code != errorCode)		throw 'NSError** failed (4)'


	// Test method signature : NSError** should be encoded with a pointer
	var sig = [JSCocoa typeEncodingOfMethod:'someMethodReturningAnError:' class:'NSErrorCallback']
	if (sig != 'B@:^')								throw 'NSError** signature failed'
	
	
	
	o = null
	
	
	