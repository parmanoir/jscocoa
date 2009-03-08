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

//
// JSCocoaController
//
@interface JSCocoaController : NSObject {

	JSGlobalContextRef	ctx;
    id _delegate;
}

@property (assign) id delegate;

+ (id)sharedController;
+ (id)controllerFromContext:(JSContextRef)ctx;
+ (BOOL)hasSharedController;
- (JSGlobalContextRef)ctx;

//
// Evaluation
//
- (BOOL)evalJSFile:(NSString*)path;
- (BOOL)evalJSFile:(NSString*)path toJSValueRef:(JSValueRef*)returnValue;
- (JSValueRef)evalJSString:(NSString*)script;
+ (BOOL)isMaybeSplitCall:(NSString*)start forClass:(id)class;
- (JSValueRef)callJSFunction:(JSValueRef)function withArguments:(NSArray*)arguments;
- (JSValueRef)callJSFunctionNamed:(NSString*)functionName withArguments:arguments, ... NS_REQUIRES_NIL_TERMINATION;
- (id)unboxJSValueRef:(JSValueRef)jsValue;
- (BOOL)hasJSFunctionNamed:(NSString*)functionName;
- (BOOL)setObject:(id)object withName:(id)name;
- (BOOL)setObject:(id)object withName:(id)name attributes:(JSPropertyAttributes)attributes;
- (BOOL)removeObjectWithName:(id)name;

//
// Framework
//
- (BOOL)loadFrameworkWithName:(NSString*)name;
- (BOOL)loadFrameworkWithName:(NSString*)frameworkName inPath:(NSString*)path;

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

- (const char*)typeEncodingOfMethod:(NSString*)methodName class:(NSString*)className;



@end


//
// JSCocoa delegate methods
//

//
// Error reporting
//
@interface NSObject (JSCocoaControllerDelegateMethods)
- (void) JSCocoa:(JSCocoaController*)controller hadError:(NSString*)error onLineNumber:(NSInteger)lineNumber atSourceURL:(id)url;

//
// Getting
//
// Check if getting property is allowed
- (BOOL) JSCocoa:(JSCocoaController*)controller canGetProperty:(NSString*)propertyName ofObject:(id)object inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;
// Custom handler for getting properties
//	Bypass JSCocoa and return a custom JSValueRef
//	Return NULL to let JSCocoa handle getProperty
//	Return JSValueMakeNull() to return a Javascript null
- (JSValueRef) JSCocoa:(JSCocoaController*)controller getProperty:(NSString*)propertyName ofObject:(id)object inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;

//
// Setting
//
// Check if setting property is allowed
- (BOOL) JSCocoa:(JSCocoaController*)controller canSetProperty:(NSString*)propertyName ofObject:(id)object toValue:(JSValueRef)value inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;
// Custom handler for setting properties
//	Return YES to indicate you handled setting
//	Return NO to let JSCocoa handle setProperty
- (BOOL) JSCocoa:(JSCocoaController*)controller setProperty:(NSString*)propertyName ofObject:(id)object toValue:(JSValueRef)value inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;

//
// Calling
//
// Check if calling an ObjC method is allowed
- (BOOL) JSCocoa:(JSCocoaController*)controller canCallMethod:(NSString*)methodName ofObject:(id)object inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;
// Check if calling a C function is allowed
- (BOOL) JSCocoa:(JSCocoaController*)controller canCallFunction:(NSString*)functionName inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;
// Custom handler for calling
//	Return YES to indicate you handled calling
//	Return NO to let JSCocoa handle calling
- (BOOL) JSCocoa:(JSCocoaController*)controller callFunction:(NSString*) arguments:(JSValueRef*)arguments argumentCount:(int)argumentCount inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;

//
// Returning values to Javascript
//
// Called before returning any value to Javascript : return a new value or the original one
- (JSValueRef) JSCocoa:(JSCocoaController*)controller willReturnValue:(JSValueRef)value inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;

//
// Evaling
//
// Check if file can be loaded
- (NSString*)JSCocoa:(JSCocoaController*)controller canLoadJSFile:(NSString*)script;
// Check if script can be evaluated
- (NSString*)JSCocoa:(JSCocoaController*)controller canEvaluateScript:(NSString*)script;
// Called before evalJSString
//	Return a custom NSString (eg a macro expanded version of the source)
//	Return NULL to let JSCocoa handle evaluation
- (NSString*)JSCocoa:(JSCocoaController*)controller willEvaluateScript:(NSString*)script;

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

id	JSLocalizedString(id stringName, id firstArg, ...) NS_REQUIRES_NIL_TERMINATION;


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

