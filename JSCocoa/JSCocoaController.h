//
//  JSCocoa.h
//  JSCocoa
//
//  Created by Patrick Geiller on 09/07/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#if !TARGET_IPHONE_SIMULATOR && !TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>
#import <JavascriptCore/JavascriptCore.h>
#define MACOSX
#import <ffi/ffi.h>
#endif
#import "BridgeSupportController.h"
#import "JSCocoaPrivateObject.h"
#import "JSCocoaFFIArgument.h"
#import "JSCocoaFFIClosure.h"


// JS value container, used by methods wanting a straight JSValue and not a converted JS->ObjC value.
struct	JSValueRefAndContextRef
{
	JSValueRef		value;
	JSContextRef	ctx;
};


typedef struct	JSValueRefAndContextRef JSValueRefAndContextRef;

@interface JSCocoaController : NSObject {

	JSGlobalContextRef	ctx;
}

+ (id)sharedController;
+ (id)controllerFromContext:(JSContextRef)ctx;
+ (BOOL)hasSharedController;
- (JSGlobalContextRef)ctx;

//
// Garbage collection
//
+ (void)garbageCollect;
- (void)garbageCollect;
- (void)unlinkAllReferences;
+ (void)upJSCocoaPrivateObjectCount;
+ (void)downJSCocoaPrivateObjectCount;
+ (int)JSCocoaPrivateObjectCount;

+ (void)upJSValueProtectCount;
+ (void)downJSValueProtectCount;
+ (int)JSValueProtectCount;

+ (void)logInstanceStats;
- (id)instanceStats;

//
// Evaluation
//
- (BOOL)evalJSFile:(NSString*)path;
- (BOOL)evalJSFile:(NSString*)path toJSValueRef:(JSValueRef*)returnValue;
- (JSValueRefAndContextRef)evalJSString:(NSString*)script;
+ (BOOL)isMaybeSplitCall:(NSString*)start forClass:(id)class;
- (JSValueRef)callJSFunction:(JSValueRef)function withArguments:(NSArray*)arguments;
- (JSValueRef)callJSFunctionNamed:(NSString*)functionName withArguments:arguments, ... NS_REQUIRES_NIL_TERMINATION;
- (BOOL)hasJSFunctionNamed:(NSString*)functionName;
- (BOOL)setObject:(id)object withName:(id)name;
- (BOOL)removeObjectWithName:(id)name;


//
// Framework
//
- (BOOL)loadFrameworkWithName:(NSString*)name;
- (BOOL)loadFrameworkWithName:(NSString*)frameworkName inPath:(NSString*)path;

//
// Class handling
//
+ (BOOL)overloadInstanceMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext;
+ (BOOL)overloadClassMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext;

+ (BOOL)addClassMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext encoding:(char*)encoding;
+ (BOOL)addInstanceMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext encoding:(char*)encoding;

// Tests
- (BOOL)runTests:(NSString*)path;

//
// Autorelease pool
//
+ (void)allocAutoreleasePool;
+ (void)deallocAutoreleasePool;

//
// Global boxer : only one JSValueRef for multiple box requests of one pointer
//
+ (JSObjectRef)boxedJSObject:(id)o inContext:(JSContextRef)ctx;
+ (void)downBoxedJSObjectCount:(id)o;


//
// Various internals
//
+ (JSObjectRef)jsCocoaPrivateObjectInContext:(JSContextRef)ctx;
+ (NSMutableArray*)parseObjCMethodEncoding:(const char*)typeEncoding;
+ (NSMutableArray*)parseCFunctionEncoding:(NSString*)xml functionName:(NSString**)functionNamePlaceHolder;

+ (void)ensureJSValueIsObjectAfterInstanceAutocall:(JSValueRef)value inContext:(JSContextRef)ctx;
- (NSString*)formatJSException:(JSValueRef)exception;
- (id)selectorForJSFunction:(JSObjectRef)function;

- (BOOL)useAutoCall;
- (void)setUseAutoCall:(BOOL)b;



@end

//
// JSCocoa shorthand
//
@interface JSCocoa : JSCocoaController
@end

//
// Boxed object cache : holds one JSObjectRef for each reference to a pointer
//
@interface BoxedJSObject : NSObject {
	JSObjectRef	jsObject;
}
- (void)setJSObject:(JSObjectRef)o;
- (JSObjectRef)jsObject;

@end

//
// Helpers
//
id	NSStringFromJSValue(JSValueRef value, JSContextRef ctx);
//void* malloc_autorelease(size_t size);


//
// From PyObjC : when to call objc_msgSendStret, for structure return
//		Depending on structure size & architecture, structures are returned as function first argument (done transparently by ffi) or via registers
//

#if defined(__ppc__)
#   define SMALL_STRUCT_LIMIT	4
#elif defined(__ppc64__)
#   define SMALL_STRUCT_LIMIT	8
#elif defined(__i386__) 
#   define SMALL_STRUCT_LIMIT 	8
#elif defined(__x86_64__) 
#   define SMALL_STRUCT_LIMIT	16
#elif TARGET_OS_IPHONE
// TOCHECK
#   define SMALL_STRUCT_LIMIT	4
#else
#   error "Unsupported MACOSX platform"
#endif

