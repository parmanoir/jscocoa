//
//  BurksPool.m
//  iPhoneTest2
//
//  Created by Patrick Geiller on 19/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "BurksPool.h"
#import "JSCocoaController.h"
#import "JSCocoaFFIArgument.h"
#import <objc/runtime.h>


// Parsed instance implementations for class 
// IMPs[encoding] = matchingIMP
static	id IMPs = nil;
static	id methodEncodings = nil;
// Imported from JSCocoaController
static	id jsFunctionHash = nil;

//static	JSContextRef ctx = nil;
/*
	// Given a jsFunction, retrieve its closure (jsFunction's pointer address is used as key)
	static	id	closureHash;
	// Given a jsFunction, retrieve its selector
	static	id	jsFunctionSelectors;
	// Given a jsFunction, retrieve which class it's attached to
	static	id	jsFunctionClasses;
	// Given a class, return the parent class implementing JSCocoaHolder method
	static	id	jsClassParents;
	
	// Given a class + methodName, retrieve its jsFunction
	static	id	jsFunctionHash;
	
	// Split call cache
	static	id	splitCallCache;

	// Shared instance stats
	static	id	sharedInstanceStats	= nil;
	
	// Boxed objects
	static	id	boxedObjects;
*/

//void callJSFunction()
//{
/*
	JSObjectRef jsFunctionObject = JSValueToObject(ctx, jsFunction, NULL);
	JSValueRef	exception = NULL;
	

	// ## Only objC for now. Need to test C function pointers.
	
	// Argument count is encodings count minus return value
	int	i, idx = 0, effectiveArgumentCount = [encodings count]-1;
	// Skip self and selector
	if (isObjC)
	{
		effectiveArgumentCount -= 2;
		idx = 2;
	}
	// Convert arguments
	JSValueRef*	args = NULL;
	if (effectiveArgumentCount)
	{
		args = malloc(effectiveArgumentCount*sizeof(JSValueRef));
		for (i=0; i<effectiveArgumentCount; i++, idx++)
		{
			// +1 to skip return value
			id encodingObject = [encodings objectAtIndex:idx+1];

			id arg = [[JSCocoaFFIArgument alloc] init];
			char encoding = [encodingObject typeEncoding];
			if (encoding == '{')	[arg setStructureTypeEncoding:[encodingObject structureTypeEncoding] withCustomStorage:*(void**)&closureArgs[idx]];
			else					[arg setTypeEncoding:[encodingObject typeEncoding] withCustomStorage:closureArgs[idx]];
			
			args[i] = NULL;
			[arg toJSValueRef:&args[i] inContext:ctx];
			
			[arg release];
		}
	}
	
	JSObjectRef jsThis = NULL;
	
	// Create 'this'
	if (isObjC)
		jsThis = [JSCocoaController boxedJSObject:*(void**)closureArgs[0] inContext:ctx];

	// Call !
	JSValueRef jsReturnValue = JSObjectCallAsFunction(ctx, jsFunctionObject, jsThis, effectiveArgumentCount, args, &exception);

	// Convert return value if it's not void
	char encoding = [[encodings objectAtIndex:0] typeEncoding];
	if (jsReturnValue && encoding != 'v')
	{
		[JSCocoaFFIArgument fromJSValueRef:jsReturnValue inContext:ctx typeEncoding:encoding fullTypeEncoding:[[encodings objectAtIndex:0] structureTypeEncoding] fromStorage:returnValue];
#ifdef __BIG_ENDIAN__
		// As ffi always uses a sizeof(long) return value (even for chars and shorts), do some shifting
		int size = [JSCocoaFFIArgument sizeOfTypeEncoding:encoding];
		int paddedSize = sizeof(long);
		long	v; 
		if (size > 0 && size < paddedSize && paddedSize == 4)
		{
			v = *(long*)returnValue;
			v = CFSwapInt32(v);
			*(long*)returnValue = v;
		}
#endif	
	}

	if (effectiveArgumentCount)	free(args);
	if (exception)	NSLog(@"%@", [[JSCocoaController controllerFromContext:ctx] formatJSException:exception]);
*/
//}


@implementation BurksPool

+ (void)setJSFunctionHash:(id)hash
{
	jsFunctionHash = hash;
}

+ (JSValueRef)callSelector:(SEL)sel ofInstance:(id)o withArguments:(void*)firstArg, ...
{
	id keyForClassAndMethod	= [NSString stringWithFormat:@"%@ %@", [o class], NSStringFromSelector(sel)];
	id encodings			= [methodEncodings objectForKey:keyForClassAndMethod];
	id privateObject		= [jsFunctionHash objectForKey:keyForClassAndMethod];

	if (!encodings)		return	NSLog(@"No encodings found for %@", keyForClassAndMethod), NULL;
	if (!privateObject)	return	NSLog(@"No js function found for %@", keyForClassAndMethod), NULL;

	JSContextRef ctx = [privateObject ctx];

	// One to skip return value, 2 to skip common ObjC message parameters (instance, selector)
	int effectiveArgumentCount = [encodings count]-1-2;
	int idx = 2+1;

	// Convert arguments
	JSValueRef*	args = NULL;
	if (effectiveArgumentCount)
	{
		args = malloc(effectiveArgumentCount*sizeof(JSValueRef));

		va_list	vaargs;
		va_start(vaargs, firstArg);
		for (int i=0; i<effectiveArgumentCount; i++, idx++)
		{
			// +1 to skip return value
			id encodingObject = [encodings objectAtIndex:idx];

			id arg = [[JSCocoaFFIArgument alloc] init];
			char encoding = [encodingObject typeEncoding];
			
			void* currentArg;
			if (i == 0)	currentArg = firstArg;
			else
			{
				currentArg = va_arg(vaargs, void*);
			}
			
			if (encoding == '{')	[arg setStructureTypeEncoding:[encodingObject structureTypeEncoding] withCustomStorage:*(void**)&currentArg];
			else					[arg setTypeEncoding:[encodingObject typeEncoding] withCustomStorage:currentArg];
			
			args[i] = NULL;
			[arg toJSValueRef:&args[i] inContext:ctx];
			if (!args[i])	args[i] = JSValueMakeUndefined(ctx);
			
			[arg release];
		}
		va_end(vaargs);
	}
	
	
	// Create 'this'
	JSObjectRef jsThis = [JSCocoaController boxedJSObject:o inContext:ctx];

	// Call !
	JSObjectRef jsFunctionObject	= JSValueToObject(ctx, [privateObject jsValueRef], NULL);
	JSValueRef	exception;
	JSValueRef	returnValue = JSObjectCallAsFunction(ctx, jsFunctionObject, jsThis, effectiveArgumentCount, args, &exception);
	
	if (effectiveArgumentCount)	free(args);
	if (exception)	NSLog(@"%@", [[JSCocoaController controllerFromContext:ctx] formatJSException:exception]);

	return returnValue;
}

- (id)v_at_sel
{
	NSLog(@"Called on get ************** self=%@", self);
	return nil;
}

- (void)setValue:(id)p1
{
//	JSValueRef args[
//	NSLog(@"Called on set ************** %@ self=%@ sel=%s", i, self, _cmd);

//	callJSFunction(self, _cmd, &p1, NULL);

	[BurksPool callSelector:_cmd ofInstance:self withArguments:&p1, &p1, &p1, NULL];


//	JSValueRef args[] = { [JSCocoaFFIArgument jsValueRefWithTypeEncoding:'@' customStorage:&i inContext:ctx] };

//	JSValueRef returnValue = callJSFunction(self, _cmd, [NSArray arrayWithObjects:
//			[JSCocoaFFIArgument jsValueRefWithTypeEncoding:'@' customStorage:&i],
//												nil);
/*
	id keyForClassAndMethod = [NSString stringWithFormat:@"%@ %@", [self class], NSStringFromSelector(_cmd)];
	id encodings = [methodEncodings objectForKey:keyForClassAndMethod];
	id privateObject = [jsFunctionHash objectForKey:keyForClassAndMethod];
	NSLog(@"%@ %@", privateObject, encodings);
	
	JSContextRef ctx = [privateObject ctx];
	JSObjectRef jsFunctionObject = JSValueToObject(ctx, [privateObject jsValueRef], NULL);

	JSObjectRef jsThis = NULL;
	int effectiveArgumentCount = 0;
	JSValueRef* args = NULL;
	JSValueRef exception = NULL;
	JSValueRef jsReturnValue = JSObjectCallAsFunction(ctx, jsFunctionObject, jsThis, effectiveArgumentCount, args, &exception);
*/	
}

//
// Flatten an encoding array to a string
//
+ (id)flattenEncoding:(id)encodings
{
	id fullEncodingArray = [NSMutableArray array];
	for (JSCocoaFFIArgument* arg in encodings)
	{
		if ([arg typeEncoding] == '{')	[fullEncodingArray addObject:[arg structureTypeEncoding]];
		else							[fullEncodingArray addObject:[NSString stringWithFormat:@"%c", [arg typeEncoding]]];
	}
	id fullEncoding = [fullEncodingArray componentsJoinedByString:@""];
	return	fullEncoding;
}

//
// Gather instance method implementations, removing ObjC indices ( - (id)method:(id)param -> @8@0:4 -> @@:)
//
+ (void)gatherIMPs
{
	IMPs = [[NSMutableDictionary alloc] init];
	unsigned int methodCount;
	Method* methods = class_copyMethodList([self class], &methodCount);
	for (int i=0; i<methodCount; i++)
	{
		Method m = methods[i];
		IMP imp = method_getImplementation(m);
		id encoding = [self flattenEncoding:[JSCocoaController parseObjCMethodEncoding:method_getTypeEncoding(m)]];
//		NSLog(@"(%d) sel=%s enc=%s ENC2=%@", i, method_getName(m), method_getTypeEncoding(m), encoding);
		[IMPs setObject:[NSNumber numberWithUnsignedLong:(long)imp] forKey:encoding];
	}
	free(methods);
}

//
//  Given a type encoding, retrieve a method implementation
//
+ (IMP)IMPforTypeEncodings:(NSArray*)encodings
{
	if (!IMPs)	[self gatherIMPs];
	
	id encoding = [self flattenEncoding:encodings];
	
	NSNumber* IMPnumber = [IMPs objectForKey:encoding];
//	NSLog(@"enc=%@*** IMP=%@", encoding, IMPnumber);
	if (IMPnumber)	return (IMP)[IMPnumber unsignedLongValue];
	return	nil;
}

//
// Register encoding (this is only for cache, this could be removed and encodings gotten at runtime like the Mac code does)
//
+ (BOOL)addMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext encodings:(id)encodings
{
//	NSLog(@"Adding %@.%@", class, methodName);
	id keyForClassAndMethod = [NSString stringWithFormat:@"%@ %@", class, methodName];
//	id keyForFunction = [NSString stringWithFormat:@"%x", valueAndContext.value];
	if (!methodEncodings)	methodEncodings = [[NSMutableDictionary alloc] init];
	[methodEncodings setObject:encodings forKey:keyForClassAndMethod];
	return	YES;
}



@end
