//
//  JSCocoaPrivateObject.m
//  JSCocoa
//
//  Created by Patrick Geiller on 09/07/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "JSCocoaPrivateObject.h"
#import "JSCocoaController.h"

@implementation JSCocoaPrivateObject

@synthesize type, xml, declaredType, methodName, structureName, isAutoCall;


- (id)init
{
	self = [super init];
	type = xml = declaredType = methodName = nil;
	object		= nil;
	isAutoCall	= NO;
	jsValue		= NULL;
	retainObject	= YES;
//	retainContext	= NO;
	rawPointer	= NULL;
	ctx			= NULL;
	
	
	[JSCocoaController upJSCocoaPrivateObjectCount];
	return	self;
}

- (void)cleanUp
{
	[JSCocoaController downJSCocoaPrivateObjectCount];
//	if (object)	NSLog(@"GO for JSCocoaPrivateObject release (%@) %x %d", [object class], object, [object retainCount]);
//	if (object)	[JSCocoaController downBoxedJSObjectCount:object];
	if (object && retainObject)
	{
		[JSCocoaController downBoxedJSObjectCount:object];
//		NSLog(@"released !");
		[object release];
	}
	if (jsValue)		
	{
		JSValueUnprotect(ctx, jsValue);
		[JSCocoaController downJSValueProtectCount];
	}
/*
	if (retainContext)
	{
		NSLog(@"releasing %x", ctx);
		JSContextGroupRelease(contextGroup);
//		JSGlobalContextRelease((JSGlobalContextRef)ctx);
	}
*/	
	// Release properties
	[type release];
	[xml release];
	[methodName release];
	[structureName release];
	[declaredType release];
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

- (void)setObject:(id)o
{
	object = o;
	if (object && [object retainCount] == -1)	return;
	[object retain];
}

- (void)setObjectNoRetain:(id)o
{
	object			= o;
	retainObject	= NO;
}

- (BOOL)retainObject
{
	return	retainObject;
}


- (id)object
{
	return	object;
}

- (void)setMethod:(Method)m
{
	method = m;
}
- (Method)method
{
	return method;
}

- (void)setJSValueRef:(JSValueRef)v ctx:(JSContextRef)c;
{
	// While autocalling we'll get a NULL value when boxing a void return type - just skip JSValueProtect
	if (!v)	
	{
//		NSLog(@"setJSValueRef: NULL value");
		jsValue = 0;
		return;
	}
	jsValue = v;
//	ctx		= c;
	// Register global context (this would crash the launcher as JSValueUnprotect was called on a destroyed context)
	ctx		= [[JSCocoaController controllerFromContext:c] ctx];
	JSValueProtect(ctx, jsValue);
	[JSCocoaController upJSValueProtectCount];
}
- (JSValueRef)jsValueRef
{
	return	jsValue;
}

- (JSContextRef)ctx
{
	return	ctx;
}


- (void)setExternalJSValueRef:(JSValueRef)v ctx:(JSContextRef)c
{
	if (!v)	
	{
		jsValue = 0;
		return;
	}
	jsValue = v;
	ctx		= c;
//	contextGroup = JSContextGetGroup(c);
//	JSContextGroupRetain(contextGroup);
//	JSGlobalContextRetain((JSGlobalContextRef)ctx);
	JSValueProtect(ctx, jsValue);
//	retainContext = YES;
	[JSCocoaController upJSValueProtectCount];
}


- (void*)rawPointer	
{
	return	rawPointer;
}
- (void)setRawPointer:(void*)rp encoding:(id)encoding
{
	rawPointer = rp;
//	NSLog(@"RAWPOINTER=%@", encoding);
	declaredType = encoding;
	[declaredType retain];
}

- (id)rawPointerEncoding
{
	return	declaredType;
}


- (id)description
{
	id extra = @"";
	if ([type isEqualToString:@"rawPointer"]) extra = [NSString stringWithFormat:@" (%x) %@", rawPointer, declaredType];
	return [NSString stringWithFormat:@"<%@: %x holding %@%@>",
				[self class], 
				self, 
				type,
				extra
				];
}

- (id)dereferencedObject
{
	if (![type isEqualToString:@"rawPointer"])	return nil;
	return *(void**)rawPointer;
}

- (BOOL)referenceObject:(id)o
{
	if (![type isEqualToString:@"rawPointer"])	return NO;
//	void* v = *(void**)rawPointer;
	*(id*)rawPointer = o;
	return	YES;
}


@end

