//
//  JSCocoaLib.h
//  JSCocoa
//
//  Created by Patrick Geiller on 21/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#if !TARGET_IPHONE_SIMULATOR && !TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>
#endif
#import "JSCocoa.h"

@class JSCocoaMemoryBuffer;

@interface JSCocoaOutArgument : NSObject
{
	JSCocoaFFIArgument*		arg;
	JSCocoaMemoryBuffer*	buffer;
	int						bufferIndex;
}
- (BOOL)mateWithJSCocoaFFIArgument:(JSCocoaFFIArgument*)arg;
- (JSValueRef)outJSValueRefInContext:(JSContextRef)ctx;

@end



@interface JSCocoaMemoryBuffer : NSObject
{
	void*	buffer;
	int		bufferSize;
	// NSString holding types
	id		typeString;

	// Indicates whether types are aligned.
	// types not aligned (DEFAULT)
	//	size('fcf') = 4 + 1 + 4 = 9
	// types aligned
	//	size('fcf') = 4 + 4(align) + 4 = 12
	BOOL	alignTypes;
}

- (id)initWithTypes:(id)types;
//- (id)initWithTypes:(id)types andValues:(id)values;
//- (id)initWithMemoryBuffers:(id)buffers;

- (void*)pointerForIndex:(int)index;
- (char)typeAtIndex:(int)index;
- (JSValueRef)valueAtIndex:(int)index inContext:(JSContextRef)ctx;
- (BOOL)setValue:(JSValueRef)jsValue atIndex:(int)index inContext:(JSContextRef)ctx;
- (int)typeCount;

@end