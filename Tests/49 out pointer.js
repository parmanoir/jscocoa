

	//
	// Write something at some address
	//	In particular, return an NSError in a method
	//

	@implementation NSErrorCallback : NSObject
	
		- (BOOL)someMethodReturningAnError:(NSError**)outError
		{
			memwrite(outError, error)
			var readerror = memread(outError)
			
			if (readerror != error)					throw 'NSError** read/write failed'
			
			return	res
		}
	
	@end
	
	var o = [NSErrorCallback instance]
	
	
	var res = true
	
	var errorString	= 'NSErrorCallback test'
	var errorCode	= '503'
	var error		= [NSError errorWithDomain:errorString code:errorCode userInfo:nil]
	
	
	
	var delegate = NSApplication.sharedApplication.delegate
	
	// Call us back
	var res = true
	var b = [delegate callbackNSErrorWithClass:o]
	
	var errorFromDelegate = [delegate testNSError]
	if (errorFromDelegate.domain != errorString)	throw 'NSError** failed (1)'
	if (errorFromDelegate.code != errorCode)		throw 'NSError** failed (1)'
	
/*	
	log('b=' + b)
	log('error=' + [delegate testNSError])
	
	

*/	var sig = [JSCocoa typeEncodingOfMethod:'someMethodReturningAnError:' class:'NSErrorCallback']
	if (sig != 'B@:^')								throw 'NSError** signature failed'
	
	
	
	o = null