//
//  JSCocoaLib.h
//  JSCocoa
//
//  Created by Patrick Geiller on 21/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JSCocoa.h"


@interface JSCocoaOutArgument : NSObject
{
	
	void*		ptr;
	char		typeEncoding;
	id			structureTypeEncoding;
	
	JSCocoaFFIArgument*	arg;
}

//- (id)init;
//- (void)dealloc;

//- (BOOL)pushData:(?)data ofType:(char)typeEncoding;

- (BOOL)mateWithJSCocoaFFIArgument:(JSCocoaFFIArgument*)arg;
- (JSValueRef)outJSValueRefInContext:(JSContextRef)ctx;


@end
