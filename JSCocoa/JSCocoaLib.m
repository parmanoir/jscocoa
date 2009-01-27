//
//  JSCocoaLib.m
//  JSCocoa
//
//  Created by Patrick Geiller on 21/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "JSCocoaLib.h"

@implementation JSCocoaOutArgument


- (id)init
{
	id o	= [super init];
	ptr		= NULL;
	structureTypeEncoding = nil;
	
	arg		= nil;
	return o;
}
- (void)cleanUp
{
	if (ptr)	free(ptr);
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
// ffff : 4 floats
//
- (void)addStorageForEncodings:(id)encodings
{

}

- (void)addValue:(id)v forType:(char)encoding
{
}

- (JSValueRef)outObjectInContext:(JSContextRef)ctx
{
//	JSValueRefAndContextRef ret;
//	return	ret;
	JSValueRef jsValue;
	[arg toJSValueRef:&jsValue inContext:ctx];
	return	jsValue;
}

//
//	JSCocoaOutArgument holds a JSCocoaFFIArgument around.
//	it stays alive after ffi_call and can be queried by Javascript for type modifier values.
//	
- (BOOL)mateWithJSCocoaFFIArgument:(JSCocoaFFIArgument*)_arg
{
	if (![_arg allocatePointerStorage])	return	NO;
//	ptr						= [arg storage];
//	typeEncoding			= [arg typeEncoding];
//	structureTypeEncoding	= [arg structureTypeEncoding];
//	[structureTypeEncoding retain];


	arg	= _arg;
	[arg retain];
	return	YES;
}

@end
