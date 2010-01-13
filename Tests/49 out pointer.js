

	//
	// Write something at some address
	//	In particular, return an NSError in a method
	//

	@implementation NSErrorCallback : NSObject
	
		- (BOOL)someMethodReturningAnError:(NSError**)outError
		{
//			log('outError=' + outError)
		
			// Init a memory buffer from pointer
			var b = new memoryBuffer('^')
			b[0] = outError

			// Reference error in this pointer ( *outError = error )
			[b referenceObject:error usingPointerAtIndex:0]
			// Read it back
			var readBackError1 = [b dereferenceObjectAtIndex:0]
			if (readBackError1 != error)					throw 'NSError** read/write failed (1)'

			// Read it via JSCocoaPrivateObject
			var readBackError2 = outError.dereferencedObject
			if (readBackError1 != readBackError2)			throw 'NSError** read/write failed (2)' 
			
			// null error out
			outError.referenceObject(null)
			var readBackError3 = outError.dereferencedObject
			if (readBackError3 != null)						throw 'NSError** read/write failed (3)' 

			// Write error via JSCocoaPrivateObject
			outError.referenceObject(error)
			var readBackError4 = outError.dereferencedObject
			if (readBackError4 != error)					throw 'NSError** read/write failed (4)'
			
			return	res
		}
	
		- (BOOL)someMethodReturningAnError2:(NSError**)outError
		{
			// Make sure we don't crash with anull pointer
			var o = outError.dereferencedObject
			if (o != null)									throw 'NSError** read/write failed (5)'
		
			// Init a memory buffer from pointer
			var b = new memoryBuffer('^')
			b[0] = outError

			var readBackError = [b dereferenceObjectAtIndex:0]
			if (readBackError != null)						throw 'NSError** read/write failed (6)'
			
			return	true
		}

		- (BOOL)someMethodReturningAnError3:(NSError**)outError
		{
			// Test a error written to an outArgument passed to us
			var url = [NSURL fileURLWithPath:@"/non/existent"];
			[@"hello" writeToURL:url atomically:NO encoding:NSUTF8StringEncoding error:outError];
			errorFromTest3 = outError.dereferencedObject

			return	true
		}

		- (BOOL)someMethodReturningAnError3:(NSError**)outError andInt:(int*)a
		{
			return	false
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
	
	// Test with null pointer
	[o someMethodReturningAnError2:null]


/*
	log('>>>>>>SIG' + [JSCocoa typeEncodingOfMethod:'signatureTestWithError:' class:'ApplicationController'])
	log('>>>>>>SIG' + [JSCocoa typeEncodingOfMethod:'signatureTestWithError2:andInt:' class:'ApplicationController'])
	log('>>>>>>SIG' + [JSCocoa typeEncodingOfMethod:'someMethodReturningAnError3:andInt:' class:'NSErrorCallback'])
*/

	// Test with null pointer
	var errorFromTest3 = null

	var oa = new outArgument
	[o someMethodReturningAnError3:oa]

	var error2 = oa.outValue
	if (!errorFromTest3)							throw 'NSError** failed (5)'
	if (!error2)									throw 'NSError** failed (6)'
	if (error2.domain != errorFromTest3.domain)		throw 'NSError** failed (7)'
	if (error2.code != errorFromTest3.code)			throw 'NSError** failed (7)'


	// Test method signature : NSError** should be encoded with a pointer
	var sig = [JSCocoa typeEncodingOfMethod:'someMethodReturningAnError:' class:'NSErrorCallback']
	if (sig != 'B@:^@')								throw 'NSError** signature failed'
	
	
	
	o = null
	
	
	