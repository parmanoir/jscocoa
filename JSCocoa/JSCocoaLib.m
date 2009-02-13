//
//  JSCocoaLib.m
//  JSCocoa
//
//  Created by Patrick Geiller on 21/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "JSCocoaLib.h"


//
// Handles out arguments of functions and methods.
//	eg NSOpenGLGetVersion(int*, int*) asks for two pointers to int.
//	JSCocoaOutArgument will alloc the memory through JSCocoaFFIArgument and get the result back to Javascript (check out value in JSCocoaController)
//
@implementation JSCocoaOutArgument

- (id)init
{
	self	= [super init];

	arg		= nil;
	buffer	= nil;
	return self;
}
- (void)cleanUp
{
	[arg release];
	[buffer release];
}
- (void)dealloc
{
	[self cleanUp];
	[super dealloc];
}
- (void)finalize
{
	[self cleanUp];
	[super finalize];
}


//
// convert the out value to a JSValue
//
- (JSValueRef)outJSValueRefInContext:(JSContextRef)ctx
{
	JSValueRef jsValue = NULL;
	[arg toJSValueRef:&jsValue inContext:ctx];
	return	jsValue;
}

//
//	JSCocoaOutArgument holds a JSCocoaFFIArgument around.
//	it stays alive after ffi_call and can be queried by Javascript for type modifier values.
//	
- (BOOL)mateWithJSCocoaFFIArgument:(JSCocoaFFIArgument*)_arg
{
	// If holding a memory buffer, use its pointer
	if (buffer)
	{
		arg	= _arg;
		[arg retain];

		void* ptr = [buffer pointerForIndex:bufferIndex];
		if (!ptr)	return	NO;
//		NSLog(@"mating encoding ***%c***%c***(pointerTypeEncoding=%@) on arg %x", [arg typeEncoding], [buffer typeAtIndex:bufferIndex], [arg pointerTypeEncoding], _arg);
//		[arg setTypeEncoding:[buffer typeAtIndex:bufferIndex] withCustomStorage:ptr];
		[arg setTypeEncoding:[arg typeEncoding] withCustomStorage:ptr];
		return	YES;
	}

	// Standard pointer
	if (![_arg allocatePointerStorage])	return	NO;

	arg	= _arg;
	[arg retain];
	return	YES;
}

- (BOOL)mateWithMemoryBuffer:(id)b atIndex:(int)idx
{
	if (!b || ![b isKindOfClass:[JSCocoaMemoryBuffer class]])	return	NSLog(@"mateWithMemoryBuffer called without a memory buffer (%@)", b), NO;
	buffer = b;
	[buffer retain];
	bufferIndex = idx;
	return	YES;
}

@end



//
// Instead of malloc(sizeof(float)*4), JSCocoaMemoryBuffer expects 'ffff' as an init string.
//	The buffer can be manipulated like an array (buffer[2] = 0.5) 
//		* it can be filled, calling methods to copy data in it
//			- (NSBezierPathElement)elementAtIndex:(NSInteger)index associatedPoints:(NSPointArray)points;
//		* it can be used as data source, calling methods to copy data from it
//			- (void)setAssociatedPoints:(NSPointArray)points atIndex:(NSInteger)index;
//
@implementation JSCocoaMemoryBuffer

- (id)initWithTypes:(id)_types
{
	self	= [super init];
	buffer	= NULL;

	// Copy types string
	typeString = [NSString stringWithString:_types];
	[typeString retain];

	// Compute buffer size
	const char* types = [typeString UTF8String];
	int l = [typeString length];
	bufferSize = 0;
	for (int i=0; i<l; i++)
	{
		int size = [JSCocoaFFIArgument sizeOfTypeEncoding:types[i]];
		if (size == -1)	return	NSLog(@"JSCocoaMemoryBuffer initWithTypes : unknown type %c", types[i]), self;
		bufferSize += size;
	}

	// Malloc
//	NSLog(@"mallocing %d bytes for %@", bufferSize, typeString);
	buffer = malloc(bufferSize);
	
	return	self;
}

- (void)dealloc	
{
	if (buffer)	free(buffer);
	[typeString release];
	[super dealloc];
}
- (void)finalize
{
	if (buffer)	free(buffer);
	[super finalize];
}

//
// Returns pointer for index without any padding
//
- (void*)pointerForIndex:(int)index
{
	const char* types = [typeString UTF8String];
	void* pointedValue = buffer;
	for (int i=0; i<index; i++)
	{
//		NSLog(@"advancing %c", types[i]);
		[JSCocoaFFIArgument advancePtr:&pointedValue accordingToEncoding:types[i]];
	}
	return	pointedValue;
}

- (char)typeAtIndex:(int)index
{
	if (index >= [typeString length])	return '\0';
	return	[typeString UTF8String][index];
}

- (int)typeCount
{
	return	[typeString length];
}


//
// Using JSValueRefAndContextRef as input to get the current context in which to create the return value
//
- (JSValueRef)valueAtIndex:(int)index inContext:(JSContextRef)ctx
{
	char	typeEncoding = [self typeAtIndex:index];
	void*	pointedValue = [self pointerForIndex:index];

	JSValueRef returnValue;
	[JSCocoaFFIArgument toJSValueRef:&returnValue inContext:ctx withTypeEncoding:typeEncoding withStructureTypeEncoding:nil fromStorage:pointedValue];
	return	returnValue;
}

- (BOOL)setValue:(JSValueRef)jsValue atIndex:(int)index inContext:(JSContextRef)ctx;
{
	char	typeEncoding = [self typeAtIndex:index];
	void*	pointedValue = [self pointerForIndex:index];

	[JSCocoaFFIArgument fromJSValueRef:jsValue inContext:ctx withTypeEncoding:typeEncoding withStructureTypeEncoding:nil fromStorage:pointedValue];
	return	YES;
}




@end
