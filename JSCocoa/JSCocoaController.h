//
//  JSCocoa.h
//  JSCocoa
//
//  Created by Patrick Geiller on 09/07/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#ifndef JSCocoa_iPhone
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

	// Given a jsFunction, retrieve its closure (jsFunction's pointer address is used as key)
	id	closureHash;
	// Given a jsFunction, retrieve its selector
	id	jsFunctionSelectors;
	// Given a jsFunction, retrieve which class it's attached to
	id	jsFunctionClasses;
	// Given a class, return the parent class implementing JSCocoaHolder method
	id	jsClassParents;
	
	// Given a class + methodName, retrieve its jsFunction
	id	jsFunctionHash;
	
	// Instance stats
	id	instanceStats;
	
	// Split call cache
	id	splitCallCache;
	
	// Used to convert callbackObject (zero call)
	JSObjectRef	callbackObjectValueOfCallback;
	
	// Auto call zero arg methods : allow NSWorkspace.sharedWorkspace instead of NSWorkspace.sharedWorkspace()
	BOOL	useAutoCall;
	// If true, all exceptions will be sent to NSLog, event if they're caught later on by some Javascript core
	BOOL	logAllExceptions;
	// Is speaking when throwing exceptions
	BOOL	isSpeaking;
}

@property BOOL useAutoCall;
@property BOOL isSpeaking;
@property BOOL logAllExceptions;

+ (id)sharedController;
+ (BOOL)hasSharedController;
- (JSGlobalContextRef)ctx;

//
// Garbage collection
//
+ (void)garbageCollect;
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
- (BOOL)isMaybeSplitCall:(NSString*)start forClass:(id)class;
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
- (BOOL)overloadInstanceMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext;
- (BOOL)overloadClassMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext;

- (BOOL)addClassMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext encoding:(char*)encoding;
- (BOOL)addInstanceMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext encoding:(char*)encoding;

// Tests
- (BOOL)runTests:(NSString*)path;

//
// Autorelease pool
//
+ (void)allocAutoreleasePool;
+ (void)deallocAutoreleasePool;

//
// Various internals
//
+ (JSObjectRef)jsCocoaPrivateObjectInContext:(JSContextRef)ctx;
+ (NSMutableArray*)parseObjCMethodEncoding:(const char*)typeEncoding;
+ (NSMutableArray*)parseCFunctionEncoding:(NSString*)xml functionName:(NSString**)functionNamePlaceHolder;

- (JSObjectRef)callbackObjectValueOfCallback;
+ (void)ensureJSValueIsObjectAfterInstanceAutocall:(JSValueRef)value inContext:(JSContextRef)ctx;
- (NSString*)formatJSException:(JSValueRef)exception;
- (id)selectorForJSFunction:(JSObjectRef)function;


@end

//
// JSCocoa shorthand
//
@interface JSCocoa : JSCocoaController
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

