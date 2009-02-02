//
//  JSCocoaPrivateObject.h
//  JSCocoa
//
//  Created by Patrick Geiller on 09/07/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#if !TARGET_IPHONE_SIMULATOR && !TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>
#import <JavascriptCore/JavascriptCore.h>
#endif
#import <mach-o/dyld.h>
#import <dlfcn.h>
//#import <objc/objc-class.h>
#import <objc/runtime.h>
#import <objc/message.h>

//
// Boxing object
//	type
//	@			ObjC object
//	struct		C struct
//	method		ObjC method name
//	rawPointer	raw C pointer (_C_PTR)
//	function	Javascript function
//

@interface JSCocoaPrivateObject : NSObject {

	NSString*	type;
	NSString*	xml;
	NSString*	methodName;
	NSString*	structureName;
	
	NSString*	declaredType;
//	void*		ptr;
	void*		rawPointer;

	id			object;

	Method		method;
	
	JSValueRef	jsValue;
	JSContextRef	ctx;
	
	BOOL		isAutoCall;
	BOOL		retainObject;
}

@property (copy) NSString*	type;
@property (copy) NSString*	xml;
@property (copy) NSString*	methodName;
@property (copy) NSString*	structureName;
@property (copy) NSString*	declaredType;
@property BOOL	isAutoCall;

//- (void)setPtr:(void*)ptrValue;
//- (void*)ptr;

- (void)setObject:(id)o;
- (void)setObjectNoRetain:(id)o;
- (id)object;

- (void)setMethod:(Method)m;
- (Method)method;

- (void)setJSValueRef:(JSValueRef)v ctx:(JSContextRef)ctx;
- (JSValueRef)jsValueRef;

- (void*)rawPointer;
- (void)setRawPointer:(void*)rp;

@end
