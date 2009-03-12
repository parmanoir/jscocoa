//
//  JSCocoa.m
//  JSCocoa
//
//  Created by Patrick Geiller on 09/07/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//


#import "JSCocoaController.h"
#import "JSCocoaLib.h"

#pragma mark JS objects forward definitions

// Global object
static	JSValueRef	OSXObject_getProperty(JSContextRef, JSObjectRef, JSStringRef, JSValueRef*);

// Private JS object callbacks
static	void		jsCocoaObject_initialize(JSContextRef, JSObjectRef);
static	void		jsCocoaObject_finalize(JSObjectRef);
static	JSValueRef	jsCocoaObject_callAsFunction(JSContextRef, JSObjectRef, JSObjectRef, size_t, const JSValueRef [], JSValueRef*);
static	JSValueRef	jsCocoaObject_getProperty(JSContextRef, JSObjectRef, JSStringRef, JSValueRef*);
static	bool		jsCocoaObject_setProperty(JSContextRef, JSObjectRef, JSStringRef, JSValueRef, JSValueRef*);
static	bool		jsCocoaObject_deleteProperty(JSContextRef, JSObjectRef, JSStringRef, JSValueRef*);
static	void		jsCocoaObject_getPropertyNames(JSContextRef, JSObjectRef, JSPropertyNameAccumulatorRef);
static	JSObjectRef jsCocoaObject_callAsConstructor(JSContextRef, JSObjectRef, size_t, const JSValueRef [], JSValueRef*);
static	JSValueRef	jsCocoaObject_convertToType(JSContextRef ctx, JSObjectRef object, JSType type, JSValueRef* exception);
static	JSValueRef	_jsCocoaObject_callUsingNSInvocation(JSContextRef ctx, id callee, NSString *methodName, size_t argumentCount, JSValueRef arguments[]);

// valueOf() is called by Javascript on objects, eg someObject + ' someString'
static	JSValueRef	valueOfCallback(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception);
// Set on valueOf callback property of objects
#define	JSCocoaInternalAttribute kJSPropertyAttributeDontEnum

// These will always stay alive, even after last JSCocoa has died
static	JSClassRef			OSXObjectClass		= NULL;
static	JSClassRef			jsCocoaObjectClass	= NULL;
static	JSClassRef			hashObjectClass		= NULL;

// Convenience method to throw a Javascript exception
static void throwException(JSContextRef ctx, JSValueRef* exception, NSString* reason);


// iPhone specifics
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
const JSClassDefinition kJSClassDefinitionEmpty = { 0, 0, 
													NULL, NULL, 
													NULL, NULL, 
													NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL };
#import "GDataDefines.h"
#import "GDataXMLNode.h"
#endif


//
// JSCocoaController
//
#pragma mark JSCocoaController

@interface JSCocoaController (Private)
- (void) callDelegateForException:(JSValueRef)exception;
@end

@implementation JSCocoaController

@synthesize delegate=_delegate;

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


	// Auto call zero arg methods : allow NSWorkspace.sharedWorkspace instead of NSWorkspace.sharedWorkspace()
	static	BOOL	useAutoCall;
	// If true, all exceptions will be sent to NSLog, event if they're caught later on by some Javascript core
	static	BOOL	logAllExceptions;
	// Is speaking when throwing exceptions
	static	BOOL	isSpeaking;
	
	// Controller count
	static	int		controllerCount = 0;

//
// Init
//
- (id)init
{
//	NSLog(@"JSCocoa : %x spawning", self);
	self	= [super init];
	controllerCount++;

	@synchronized(self)
	{
		if (!sharedInstanceStats)	
		{
			sharedInstanceStats = [[NSMutableDictionary alloc] init];
			closureHash			= [[NSMutableDictionary alloc] init];
			jsFunctionSelectors	= [[NSMutableDictionary alloc] init];
			jsFunctionClasses	= [[NSMutableDictionary alloc] init];
			jsFunctionHash		= [[NSMutableDictionary alloc] init];
			splitCallCache		= [[NSMutableDictionary alloc] init];
			jsClassParents		= [[NSMutableDictionary alloc] init];
			boxedObjects		= [[NSMutableDictionary alloc] init];

			useAutoCall			= YES;
			isSpeaking			= YES;
			isSpeaking			= NO;
			logAllExceptions	= NO;
		}
	}


	//
	// OSX object javascript definition
	//
	JSClassDefinition OSXObjectDefinition	= kJSClassDefinitionEmpty;
	OSXObjectDefinition.getProperty	= OSXObject_getProperty;
	if (!OSXObjectClass)
		OSXObjectClass = JSClassCreate(&OSXObjectDefinition);


	//
	// Private object, used for holding references to objects, classes, function names, structs
	//
	JSClassDefinition jsCocoaObjectDefinition	= kJSClassDefinitionEmpty;
	jsCocoaObjectDefinition.initialize			= jsCocoaObject_initialize;
	jsCocoaObjectDefinition.finalize			= jsCocoaObject_finalize;
	jsCocoaObjectDefinition.getProperty			= jsCocoaObject_getProperty;
	jsCocoaObjectDefinition.setProperty			= jsCocoaObject_setProperty;
	jsCocoaObjectDefinition.deleteProperty		= jsCocoaObject_deleteProperty;
	jsCocoaObjectDefinition.getPropertyNames	= jsCocoaObject_getPropertyNames;
	jsCocoaObjectDefinition.callAsFunction		= jsCocoaObject_callAsFunction;
	jsCocoaObjectDefinition.callAsConstructor	= jsCocoaObject_callAsConstructor;
	jsCocoaObjectDefinition.convertToType		= jsCocoaObject_convertToType;
	
	if (!jsCocoaObjectClass)
		jsCocoaObjectClass = JSClassCreate(&jsCocoaObjectDefinition);
	
	//
	// Private Hash of derived classes, storing js values
	//
	JSClassDefinition jsCocoaHashObjectDefinition	= kJSClassDefinitionEmpty;
	if (!hashObjectClass)
		hashObjectClass = JSClassCreate(&jsCocoaHashObjectDefinition);

	//
	// Start context
	//
	ctx = JSGlobalContextCreate(OSXObjectClass);

	// Create a reference to ourselves, and make it read only, don't enum, don't delete
	[self setObject:self withName:@"__jsc__" attributes:kJSPropertyAttributeReadOnly|kJSPropertyAttributeDontEnum|kJSPropertyAttributeDontDelete];

#if !TARGET_IPHONE_SIMULATOR && !TARGET_OS_IPHONE
	[self loadFrameworkWithName:@"AppKit"];
	[self loadFrameworkWithName:@"CoreFoundation"];
	[self loadFrameworkWithName:@"Foundation"];
	[self loadFrameworkWithName:@"CoreGraphics" inPath:@"/System/Library/Frameworks/ApplicationServices.framework/Frameworks"];
#endif	

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#endif

	// Load class kit
	id classKitPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"class" ofType:@"js"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:classKitPath])	[self evalJSFile:classKitPath];

	return	self;
}

//
// Dealloc
//
- (void)cleanUp
{
//	NSLog(@"JSCocoa : %x dying", self);
	
	[self unlinkAllReferences];
	JSGarbageCollect(ctx);

	controllerCount--;
	if (controllerCount == 0)
	{
		JSClassRelease(OSXObjectClass);
		JSClassRelease(jsCocoaObjectClass);
		JSClassRelease(hashObjectClass);

		[sharedInstanceStats release];
		[closureHash release];
		[jsFunctionSelectors release];
		[jsFunctionClasses release];
		[jsFunctionHash release];
		[splitCallCache release];
		[jsClassParents release];
		[boxedObjects release];
	}

	JSGlobalContextRelease(ctx);
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
// Shared instance
//
static id JSCocoaSingleton = NULL;

+ (id)sharedController
{
	@synchronized(self)
	{
		if (!JSCocoaSingleton)
		{
			// 1. alloc
			// 2. store pointer 
			// 3. call init
			//	
			//	Why ? if init is calling sharedController, the pointer won't have been set and it will call itself over and over again.
			//
			JSCocoaSingleton = [self alloc];
//			NSLog(@"JSCocoa : allocating shared instance %x", JSCocoaSingleton);
			[JSCocoaSingleton init];
		}
	}
	return	JSCocoaSingleton;
}
+ (BOOL)hasSharedController
{
	return	!!JSCocoaSingleton;
}

// Retrieves the __jsc__ variable from a context and unbox it
+ (id)controllerFromContext:(JSContextRef)ctx
{
	JSStringRef jsName = JSStringCreateWithUTF8CString("__jsc__");
	JSValueRef jsValue = JSObjectGetProperty(ctx, JSContextGetGlobalObject(ctx), jsName, NULL);
	JSStringRelease(jsName);
	id jsc = nil;
	[JSCocoaFFIArgument unboxJSValueRef:jsValue toObject:&jsc inContext:ctx];
	// Commented as it falsely reports failure when controller is cleaning up while being deallocated
//	if (!jsc)	NSLog(@"controllerFromContext couldn't find found the JSCocoaController in ctx %x", ctx);
	return	jsc;
}


#pragma mark Script evaluation

//
// Evaluate a file
// 
- (BOOL)evalJSFile:(NSString*)path toJSValueRef:(JSValueRef*)returnValue
{
	NSError*	error;
	id script = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
	// Skip .DS_Store and directories
	if (script == nil)	return	NSLog(@"evalJSFile could not open %@ (%@) — Check file encoding (should be UTF8) and file build phase (should be in \"Copy Bundle Resources\")", path, error), NO;
	
	//
	// Delegate canLoadJSFile
	//
	if (_delegate && [_delegate respondsToSelector:@selector(JSCocoa:canLoadJSFile:)] && ![_delegate JSCocoa:self canLoadJSFile:path])	return	NO;
	
	// Expand macros
	if ([self hasJSFunctionNamed:@"expandJSMacros"])
	{
		id expandedScript = [self unboxJSValueRef:[self callJSFunctionNamed:@"expandJSMacros" withArguments:script, nil]];
		// Bail if expansion failed
		if (!expandedScript || ![expandedScript isKindOfClass:[NSString class]])	
		{
			return NSLog(@"Macro expansion failed on %@ (%@)", path, expandedScript), NO;
		}
		script = expandedScript;
	}

	//
	// Delegate canEvaluateScript, willEvaluateScript
	//
	if (_delegate)
	{
		if ([_delegate respondsToSelector:@selector(JSCocoa:canEvaluateScript:)] && ![_delegate JSCocoa:self canEvaluateScript:script])	return	NO;
		if ([_delegate respondsToSelector:@selector(JSCocoa:willEvaluateScript:)])	script = [_delegate JSCocoa:self willEvaluateScript:script];
	}
	
	// Convert script and script URL to js strings
//	JSStringRef scriptJS		= JSStringCreateWithUTF8CString([script UTF8String]);
	// Using CreateWithUTF8 yields wrong results on PPC
	JSStringRef scriptJS = JSStringCreateWithCFString((CFStringRef)script);
	JSStringRef scriptURLJS		= JSStringCreateWithUTF8CString([path UTF8String]);
	// Eval !
	JSValueRef	exception = NULL;
	JSValueRef result = JSEvaluateScript(ctx, scriptJS, NULL, scriptURLJS, 1, &exception);
	if (returnValue)	*returnValue = result;
	// Release
	JSStringRelease(scriptURLJS);
	JSStringRelease(scriptJS);
	if (exception) 
	{
//		NSLog(@"JSException - %@", [self formatJSException:exception]);
        [self callDelegateForException:exception];
		return	NO;
	}
	return	YES;
}

//
// Evaluate a file, without caring about return result
// 
- (BOOL)evalJSFile:(NSString*)path
{
	return	[self evalJSFile:path toJSValueRef:nil];
}

//
// Evaluate a string
// 
- (JSValueRef)evalJSString:(NSString*)script
{
	if (!script)	return	NULL;
	
	//
	// Delegate canEvaluateScript, willEvaluateScript
	//
	if (_delegate)
	{
		if ([_delegate respondsToSelector:@selector(JSCocoa:canEvaluateScript:)] && ![_delegate JSCocoa:self canEvaluateScript:script])	return	NULL;
		if ([_delegate respondsToSelector:@selector(JSCocoa:willEvaluateScript:)])	script = [_delegate JSCocoa:self willEvaluateScript:script];
	}
	
	JSStringRef scriptJS = JSStringCreateWithCFString((CFStringRef)script);
	JSValueRef exception = NULL;
	JSValueRef result = JSEvaluateScript(ctx, scriptJS, NULL, scriptJS, 1, &exception);
	JSStringRelease(scriptJS);

	if (exception) 
	{
        [self callDelegateForException:exception];
		return	NULL;
	}

	return	result;
}

//
// Call a Javascript function by function reference (JSValueRef)
// 
- (JSValueRef)callJSFunction:(JSValueRef)function withArguments:(NSArray*)arguments
{
	JSObjectRef	jsFunction = JSValueToObject(ctx, function, NULL);
	// Return if function is not of function type
	if (!jsFunction)			return	NSLog(@"callJSFunction : value is not a function"), NULL;

	// Convert arguments
	JSValueRef* jsArguments = NULL;
	int	argumentCount = [arguments count];
	if (argumentCount)
	{
		jsArguments = malloc(sizeof(JSValueRef)*argumentCount);
		for (int i=0; i<argumentCount; i++)
		{
			char typeEncoding = _C_ID;
			id argument = [arguments objectAtIndex:i];
			[JSCocoaFFIArgument toJSValueRef:&jsArguments[i] inContext:ctx withTypeEncoding:typeEncoding withStructureTypeEncoding:NULL fromStorage:&argument];
		}
	}

	JSValueRef exception = NULL;
	JSValueRef returnValue = JSObjectCallAsFunction(ctx, jsFunction, NULL, argumentCount, jsArguments, &exception);
	if (jsArguments) free(jsArguments);

	if (exception) 
	{
//		NSLog(@"JSException in callJSFunction : %@", [self formatJSException:exception]);
        [self callDelegateForException:exception];
		return	NULL;
	}

	return	returnValue;
}

//
// Call a Javascript function by name
//	Requires nil termination : [[JSCocoa sharedController] callJSFunctionNamed:arg1, arg2, nil]
// 
- (JSValueRef)callJSFunctionNamed:(NSString*)name withArguments:(id)firstArg, ... 
{
	// Convert args to array
	id arg, arguments = [NSMutableArray array];
	if (firstArg)	[arguments addObject:firstArg];

	if (firstArg)
	{
		va_list	args;
		va_start(args, firstArg);
		while (arg = va_arg(args, id))	[arguments addObject:arg];
		va_end(args);
	}

	// Get global object
	JSObjectRef globalObject	= JSContextGetGlobalObject(ctx);
	JSValueRef exception		= NULL;
	
	// Get function as property of global object
	JSStringRef jsFunctionName = JSStringCreateWithUTF8CString([name UTF8String]);
	JSValueRef jsFunctionValue = JSObjectGetProperty(ctx, globalObject, jsFunctionName, &exception);
	JSStringRelease(jsFunctionName);
	if (exception)				
	{
//		return	NSLog(@"%@", [self formatJSException:exception]), NULL;
        [self callDelegateForException:exception];
		return	NULL;
	}
	
	JSObjectRef	jsFunction = JSValueToObject(ctx, jsFunctionValue, NULL);
	// Return if function is not of function type
	if (!jsFunction)			return	NSLog(@"callJSFunctionNamed : %@ is not a function", name), NULL;

	// Call !
	return	[self callJSFunction:jsFunction withArguments:arguments];
}


//
// Check if function exists
//
- (BOOL)hasJSFunctionNamed:(NSString*)name
{
	JSValueRef exception		= NULL;
	// Get function as property of global object
	JSStringRef jsFunctionName = JSStringCreateWithUTF8CString([name UTF8String]);
	JSValueRef jsFunctionValue = JSObjectGetProperty(ctx, JSContextGetGlobalObject(ctx), jsFunctionName, &exception);
	JSStringRelease(jsFunctionName);
	if (exception)				
	{
//		return	NSLog(@"%@", [self formatJSException:exception]), NO;
        [self callDelegateForException:exception];
		return	NO;
	}
	
	return	!!JSValueToObject(ctx, jsFunctionValue, NULL);	
}

//
// Unbox a JSValueRef
//
- (id)unboxJSValueRef:(JSValueRef)jsValue
{
	id object = nil;
	[JSCocoaFFIArgument unboxJSValueRef:jsValue toObject:&object inContext:ctx];
	return object;
}

//
// Add/Remove an ObjC object variable to the global context
//
- (BOOL)setObject:(id)object withName:(id)name attributes:(JSPropertyAttributes)attributes
{
	JSObjectRef o = [JSCocoaController boxedJSObject:object inContext:ctx];

	// Set
	JSValueRef	exception = NULL;
	JSStringRef	jsName = JSStringCreateWithUTF8CString([name UTF8String]);
	JSObjectSetProperty(ctx, JSContextGetGlobalObject(ctx), jsName, o, attributes, &exception);
	JSStringRelease(jsName);

	if (exception)	
	{
//		return	NSLog(@"JSException in setObject:withName : %@", [self formatJSException:exception]), NO;
        [self callDelegateForException:exception];
		return	NO;
	}

	return	YES;
}

- (BOOL)setObject:(id)object withName:(id)name
{
	return [self setObject:object withName:name attributes:kJSPropertyAttributeNone];
}

- (BOOL)removeObjectWithName:(id)name
{
	JSValueRef	exception = NULL;
	// Delete
	JSStringRef	jsName = JSStringCreateWithUTF8CString([name UTF8String]);
	JSObjectDeleteProperty(ctx, JSContextGetGlobalObject(ctx), jsName, &exception);
	JSStringRelease(jsName);

	if (exception)	
	{
//		return	NSLog(@"JSException in setObject:withName : %@", [self formatJSException:exception]), NO;
        [self callDelegateForException:exception];
		return	NO;
	}

	return	YES;
}





#pragma mark Loading Frameworks
- (BOOL)loadFrameworkWithName:(NSString*)name
{
	// Only check /System/Library/Frameworks for now
	return	[self loadFrameworkWithName:name inPath:@"/System/Library/Frameworks"];
}

//
// Load framework
//	even if framework has no bridgeSupport, load it anyway - it could contain ObjC classes
//
- (BOOL)loadFrameworkWithName:(NSString*)name inPath:(NSString*)inPath
{
	id path = [NSString stringWithFormat:@"%@/%@.framework/Resources/BridgeSupport/%@.bridgeSupport", inPath, name, name];

	// Return YES if already loaded
	if ([[BridgeSupportController sharedController] isBridgeSupportLoaded:path])	return	YES;

	// Load framework
	id libPath = [NSString stringWithFormat:@"%@/%@.framework/%@", inPath, name, name];
//	NSLog(@"dylib path=%@", path);
	void* address = dlopen([libPath UTF8String], RTLD_LAZY);
	if (!address)	return	NSLog(@"Could not load framework dylib %@", libPath), NO;

	// Try loading .bridgesupport file
	if (![[BridgeSupportController sharedController] loadBridgeSupport:path])	return	NSLog(@"Could not load framework bridgesupport %@", path), NO;

	// Try loading extra dylib (inline functions made callable and compiled to a .dylib)
	id extraLibPath = [NSString stringWithFormat:@"%@/%@.framework/Resources/BridgeSupport/%@.dylib", inPath, name, name];
	address = dlopen([extraLibPath UTF8String], RTLD_LAZY);
	// Don't fail if we didn't load the extra dylib as it is optional
//	if (!address)	return	NSLog(@"Did not load extra framework dylib %@", path), NO;
	
	return	YES;
}



# pragma mark Unsorted methods
+ (void)log:(NSString*)string
{
	NSLog(@"%@", string);
}
- (void)log:(NSString*)string
{
	NSLog(@"%@", string);
}
- (id)system:(NSString*)string
{
	system([string UTF8String]);
	return	nil;
}

+ (void)logAndSay:(NSString*)string
{
	[self log:string];
	if (isSpeaking)	system([[NSString stringWithFormat:@"say %@ &", string] UTF8String]);
}

+ (JSObjectRef)jsCocoaPrivateObjectInContext:(JSContextRef)ctx
{
	JSCocoaPrivateObject* private = [[JSCocoaPrivateObject alloc] init];
#ifdef __OBJC_GC__
// Mark internal object as non collectable
[[NSGarbageCollector defaultCollector] disableCollectorForPointer:private];
#endif
	JSObjectRef o = JSObjectMake(ctx, jsCocoaObjectClass, private);
	[private release];
	return	o;
}

- (BOOL)useAutoCall
{
	return	useAutoCall;
}
- (void)setUseAutoCall:(BOOL)b
{
	useAutoCall = b;
}


- (JSGlobalContextRef)ctx
{
	return	ctx;
}

- (id)instanceStats
{
	return	sharedInstanceStats;
}

//
// On auto calling 'instance' (eg NSString.instance), call is not done on property get (unlike NSWorkspace.sharedWorkspace)
// Instancing can't happen on get as instance may have parameters. 
// Instancing will therefore be delayed and must happen
//	* in fromJSValueRef
//	* in property get (NSString.instance.count, getting 'count')
//	* in valueOf (handled automatically as JavascriptCore will request 'valueOf' through property get)
//
+ (void)ensureJSValueIsObjectAfterInstanceAutocall:(JSValueRef)jsValue inContext:(JSContextRef)ctx;
{
	NSLog(@"***For zero arg instance, use obj.instance() instead of obj.instance***");
/*	
	// It's an instance if it has a property 'thisObject', holding the class name
	// value is an object holding the method name, 'instance' - its only use is storing 'thisObject'
	JSObjectRef jsObject = JSValueToObject(ctx, jsValue, NULL);

	JSStringRef name = JSStringCreateWithUTF8CString("thisObject");
	BOOL hasProperty =  JSObjectHasProperty(ctx, jsObject, name);
	JSValueRef thisObjectValue = JSObjectGetProperty(ctx, jsObject, name, NULL);
	if (hasProperty)	JSObjectDeleteProperty(ctx, jsObject, name, NULL);
	JSStringRelease(name);
	
	if (!hasProperty)	return;

	// Returning NULL will crash
	if (!thisObjectValue)	return;
	JSObjectRef thisObject = JSValueToObject(ctx, thisObjectValue, NULL);
	if (!thisObject)		return;
	JSCocoaPrivateObject* privateObject = JSObjectGetPrivate(thisObject);
	if (!thisObject)		return;

	NSLog(@"Instance autocall on class %@", [privateObject object]);

	// Create new instance and patch it into object
	id newInstance = [[[privateObject object] alloc] init];
	JSCocoaPrivateObject* instanceObject = JSObjectGetPrivate(jsObject);
	instanceObject.type = @"@";
	[instanceObject setObject:newInstance];
	// Make JS object sole owner
	[newInstance release];
*/	
}

//
// Method signature helper
//
- (const char*)typeEncodingOfMethod:(NSString*)methodName class:(NSString*)className
{
	id class = objc_getClass([className UTF8String]);
	if (!class)	return	nil;
	
	Method m = class_getClassMethod(class, NSSelectorFromString(methodName));
	if (!m)		m = class_getInstanceMethod(class, NSSelectorFromString(methodName));
	if (!m)		return	nil;
	
	return	method_getTypeEncoding(m);	
}


+ (id)parentObjCClassOfClassName:(NSString*)className
{
	return	[jsClassParents objectForKey:className];
}

#pragma mark Common encoding parsing
//
// This is parsed from method_getTypeEncoding
//
//	Later : Use method_copyArgumentType ?
+ (NSMutableArray*)parseObjCMethodEncoding:(const char*)typeEncoding
{
	id argumentEncodings = [NSMutableArray array];
	char* argsParser = (char*)typeEncoding;
	for(; *argsParser; argsParser++)
	{
		// Skip ObjC argument order
		if (*argsParser >= '0' && *argsParser <= '9')	continue;
		else
		// Skip ObjC 'const', 'oneway' markers
		if (*argsParser == 'r' || *argsParser == 'V')	continue;
		else
		if (*argsParser == '{')
		{
			// Parse structure encoding
			int count = 0;
			[JSCocoaFFIArgument typeEncodingsFromStructureTypeEncoding:[NSString stringWithUTF8String:argsParser] parsedCount:&count];

			id encoding = [[NSString alloc] initWithBytes:argsParser length:count encoding:NSUTF8StringEncoding];
			id argumentEncoding = [[JSCocoaFFIArgument alloc] init];
			// Set return value
			if ([argumentEncodings count] == 0)	[argumentEncoding setIsReturnValue:YES];
			[argumentEncoding setStructureTypeEncoding:encoding];
			[argumentEncodings addObject:argumentEncoding];
			[argumentEncoding release];

			[encoding release];
			argsParser += count-1;
		}
		else
		{
			// Custom handling for pointers as they're not one char long.
//			char type = *argsParser;
			char* typeStart = argsParser;
			if (*argsParser == '^')
				while (*argsParser && !(*argsParser >= '0' && *argsParser <= '9'))	argsParser++;

			id argumentEncoding = [[JSCocoaFFIArgument alloc] init];
			// Set return value
			if ([argumentEncodings count] == 0)	[argumentEncoding setIsReturnValue:YES];
			
			// If pointer, copy pointer type (^i, ^{NSRect}) to the argumentEncoding
			if (*typeStart == '^')
			{
				id encoding = [[NSString alloc] initWithBytes:typeStart length:argsParser-typeStart encoding:NSUTF8StringEncoding];
				[argumentEncoding setPointerTypeEncoding:encoding];
				[encoding release];
			}
			else
				[argumentEncoding setTypeEncoding:*typeStart];
			
			[argumentEncodings addObject:argumentEncoding];
			[argumentEncoding release];
		}
		if (!*argsParser)	break;
	}
	return	argumentEncodings;
}

//
// This is parsed from BridgeSupport's xml
//
+ (NSMutableArray*)parseCFunctionEncoding:(NSString*)xml functionName:(NSString**)functionNamePlaceHolder
{
	id argumentEncodings = [NSMutableArray array];
	id xmlDocument = [[NSXMLDocument alloc] initWithXMLString:xml options:0 error:nil];
	[xmlDocument autorelease];

	id rootElement = [xmlDocument rootElement];
	*functionNamePlaceHolder = [[rootElement attributeForName:@"name"] stringValue];
	
	// Parse children and return value
	int i, numChildren	= [rootElement childCount];
	id	returnValue		= NULL;
	for (i=0; i<numChildren; i++)
	{
		id child = [rootElement childAtIndex:i];
		if ([child kind] != NSXMLElementKind)	continue;
		
		BOOL	isReturnValue = [[child name] isEqualToString:@"retval"];
		if ([[child name] isEqualToString:@"arg"] || isReturnValue)
		{
			id typeEncoding = [[child attributeForName:@"type"] stringValue];
			char typeEncodingChar = [typeEncoding UTF8String][0];
		
			id argumentEncoding = [[JSCocoaFFIArgument alloc] init];
			// Set return value
			if ([argumentEncodings count] == 0)		[argumentEncoding setIsReturnValue:YES];
					if (typeEncodingChar == '{')	[argumentEncoding setStructureTypeEncoding:typeEncoding];
			else	if (typeEncodingChar == '^')
			{
				[argumentEncoding setPointerTypeEncoding:typeEncoding];
			}
			else									[argumentEncoding setTypeEncoding:typeEncodingChar];

			// Add argument
			if (!isReturnValue)
			{
				[argumentEncodings addObject:argumentEncoding];
				[argumentEncoding release];
			}
			// Keep return value on the side
			else	returnValue = argumentEncoding;
		}
	}
	
	// If no return value was set, default to void
	if (!returnValue)
	{
		id argumentEncoding = [[JSCocoaFFIArgument alloc] init];
		// Set return value
		if ([argumentEncodings count] == 0)	[argumentEncoding setIsReturnValue:YES];
		[argumentEncoding setTypeEncoding:'v'];
		returnValue = argumentEncoding;
	}
	
	// Move return value to first position  
	[argumentEncodings insertObject:returnValue atIndex:0];
	[returnValue release];
	
	return argumentEncodings;
}




#pragma mark Class Creation

+ (Class)createClass:(char*)className parentClass:(char*)parentClass
{
	Class class = objc_getClass(className);
	if (class)	return class;
	// Return now if parent class does not exist
	if (!objc_getClass(parentClass))	return	nil;
	// Each new class gets room for a js hash storing data and some get / set methods
	class = objc_allocateClassPair(objc_getClass(parentClass), className, 0);
	// Only add on classes that don't have the js data
	BOOL hasHash = !!class_getInstanceVariable(objc_getClass(parentClass), "__jsHash");
	if (!hasHash)	
	{
		// Add hash and context
		class_addIvar(class, "__jsHash", sizeof(void*), log2(sizeof(void*)), "^");
		class_addIvar(class, "__jsCocoaController", sizeof(void*), log2(sizeof(void*)), "^");
	}
	// Finish creating class
	objc_registerClassPair(class);

	// After creating class, add js methods : custom dealloc, get / set
	id JSCocoaMethodHolderClass = objc_getClass("JSCocoaMethodHolder");
	Method deallocJS = class_getInstanceMethod(JSCocoaMethodHolderClass, @selector(deallocAndCleanupJS));
	IMP deallocJSImp = method_getImplementation(deallocJS);
	if (!hasHash)
	{
	
		// Alloc debug
		Method m = class_getClassMethod(JSCocoaMethodHolderClass, @selector(allocWithZone:));
		class_addMethod(objc_getMetaClass(className), @selector(allocWithZone:), method_getImplementation(m), method_getTypeEncoding(m));	

		// Add dealloc
		class_addMethod(class, @selector(dealloc), deallocJSImp, method_getTypeEncoding(deallocJS));
		
		// Add js hash get / set /delete
		m = class_getInstanceMethod(JSCocoaMethodHolderClass, @selector(setJSValue:forJSName:));
		class_addMethod(class, @selector(setJSValue:forJSName:), method_getImplementation(m), method_getTypeEncoding(m));

		m = class_getInstanceMethod(JSCocoaMethodHolderClass, @selector(JSValueForJSName:));
		class_addMethod(class, @selector(JSValueForJSName:), method_getImplementation(m), method_getTypeEncoding(m));

		m = class_getInstanceMethod(JSCocoaMethodHolderClass, @selector(deleteJSValueForJSName:));
		class_addMethod(class, @selector(deleteJSValueForJSName:), method_getImplementation(m), method_getTypeEncoding(m));		

#ifdef __OBJC_GC__
		// GC finalize
		m = class_getInstanceMethod(JSCocoaMethodHolderClass, @selector(finalize));
		class_addMethod(class, @selector(finalize), method_getImplementation(m), method_getTypeEncoding(m));	
#endif		
	}
	
	// Retrieve parent ObjC class - used for runtime super allocWithZone: and dealloc calls
	id c = class;
	IMP existingSetJSValueImp = class_getMethodImplementation(JSCocoaMethodHolderClass, @selector(setJSValue:forJSName:));
	while (c)
	{
		IMP imp = class_getMethodImplementation(c, @selector(setJSValue:forJSName:));
		if (imp != existingSetJSValueImp)	break;
		c = [c superclass];
	}
	[jsClassParents setObject:c forKey:[NSString stringWithUTF8String:className]];
	return	class;
}



+ (BOOL)overloadInstanceMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext
{
	JSObjectRef jsObject = JSValueToObject(valueAndContext.ctx, valueAndContext.value, NULL);
	if (!jsObject)	return	NSLog(@"overloadInstanceMethod : function is not an object"), NO;
	
	SEL selector = NSSelectorFromString(methodName);
	Method m = class_getInstanceMethod(class, selector);
	if (!m)			return NSLog(@"overloadInstanceMethod : can't overload a method that does not exist - %@.%@", class, methodName), NO;
//	NSLog(@"overloading %@ (%s)", methodName, encoding);
	return	[self addInstanceMethod:methodName class:class jsFunction:valueAndContext encoding:(char*)method_getTypeEncoding(m)];
}

+ (BOOL)overloadClassMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext
{
	JSObjectRef jsObject = JSValueToObject(valueAndContext.ctx, valueAndContext.value, NULL);
	if (!jsObject)	return	NSLog(@"overloadClassMethod : function is not an object"), NO;
	
	SEL selector = NSSelectorFromString(methodName);
	Method m = class_getClassMethod(class, selector);
	if (!m)			return NSLog(@"overloadClassMethod : can't overload a method that does not exist - %@.%@", class, methodName), NO;
//	NSLog(@"overloading class method %@ (%s)", methodName, encoding);
	return	[self addClassMethod:methodName class:class jsFunction:valueAndContext encoding:(char*)method_getTypeEncoding(m)];
}

/*

	Add a JS function as method on a Cocoa class

	Given a js function, and using its pointer as a key
		* register a unique key (class + methodName) in jsFunctionHash, used to delete existing closures when setting a new method
		* register its associated methodName in jsFunctionSelectors, its associated class in jsFunctionClasses
			used when calling super (this.Super(arguments)) to get methodName and className from a jsFunction

	The closure made from the jsFunction+its encoding is stored in closureHash.

*/
+ (BOOL)addMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext encoding:(char*)encoding
{
	SEL selector = NSSelectorFromString(methodName);

	id keyForClassAndMethod = [NSString stringWithFormat:@"%@ %@", class, methodName];
	id keyForFunction = [NSString stringWithFormat:@"%x", valueAndContext.value];

	id existingMethodForJSFunction = [closureHash valueForKey:keyForFunction];
	if (existingMethodForJSFunction)
	{
		NSLog(@"jsFunction proposed for %@.%@ already registered", class, methodName);
		return	NO;
	}

//	NSLog(@"keyForFunction=%x for %@.%@", keyForFunction, class, methodName);
	
	id jsc = [JSCocoaController controllerFromContext:valueAndContext.ctx];
	JSContextRef ctx = [jsc ctx];
	id privateObject = [[JSCocoaPrivateObject alloc] init];
	[privateObject setJSValueRef:valueAndContext.value ctx:ctx];

	//	Remove previous method
	id existingPrivateObject = [jsFunctionHash objectForKey:keyForClassAndMethod];

	// Closure cleanup - dangerous as instances might still be around AND IF dealloc/release is overloaded
	if (existingPrivateObject)
	{
		id keyForExistingFunction = [NSString stringWithFormat:@"%x", [existingPrivateObject jsValueRef]];

		[closureHash			removeObjectForKey:keyForExistingFunction];
		[jsFunctionSelectors	removeObjectForKey:keyForExistingFunction];
		[jsFunctionClasses		removeObjectForKey:keyForExistingFunction];
		[jsFunctionHash			removeObjectForKey:keyForClassAndMethod];
	}
	
	[jsFunctionHash setObject:privateObject forKey:keyForClassAndMethod];
	[privateObject release];

	id closure = [[JSCocoaFFIClosure alloc] init];
	[closureHash setObject:closure forKey:keyForFunction];
	[closure release];

	// Make a FFI closure, a function pointer callable with the argument encodings we provide)
	id typeEncodings = [JSCocoaController parseObjCMethodEncoding:encoding];
	IMP fn = [closure setJSFunction:valueAndContext.value inContext:ctx argumentEncodings:typeEncodings objC:YES];

	// If successful, set it as method
	if (fn)
	{
		// First addMethod : use class_addMethod to set closure
		if (!class_addMethod(class, selector, fn, encoding))
		{
			// After that, we need to patch the method's implementation to set closure
			Method method = class_getInstanceMethod(class, selector);
			if (!method)	method = class_getClassMethod(class, selector);
			method_setImplementation(method, fn);
		}
		// Register selector for jsFunction 
		[jsFunctionSelectors setObject:methodName forKey:keyForFunction];
		[jsFunctionClasses setObject:class forKey:keyForFunction];
	}
	else
		return	NSLog(@"addMethod %@ on %@ FAILED : no functionPointer in closure", methodName, class), NO;

	return	YES;
}


+ (BOOL)addInstanceMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext encoding:(char*)encoding
{
	return [self addMethod:methodName class:class jsFunction:valueAndContext encoding:encoding];
}
+ (BOOL)addClassMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext encoding:(char*)encoding
{
	return [self addMethod:methodName class:objc_getMetaClass(class_getName(class)) jsFunction:valueAndContext encoding:encoding];
}

#pragma mark Split call

/*
	From a split call
		object.set( { value : 5, forKey : 'messageCount' } )

	Find the matching selector and set new values for methodName, argumentCount, arguments
		object.setValue_forKey_(5, 'messageCount')

	After calling, arguments NEED TO BE DEALLOCATED if they changed.
	-> introduced because under GC, NSData gets collected early.

*/
+ (BOOL)trySplitCall:(id*)_methodName class:(Class)class argumentCount:(size_t*)_argumentCount arguments:(JSValueRef**)_arguments ctx:(JSContextRef)c
{
	id methodName			= *_methodName;
	int argumentCount		= *_argumentCount;
	JSValueRef* arguments	= *_arguments;
	if (argumentCount != 1)	return	NO;

	// Get property array
	JSObjectRef o = JSValueToObject(c, arguments[0], NULL);
	if (!o)	return	NO;
	JSPropertyNameArrayRef jsNames = JSObjectCopyPropertyNames(c, o);
	
	// Convert js names to NSString names : { jsName1 : value1, jsName2 : value 2 } -> NSArray[name1, name2]
	id names = [NSMutableArray array];
	int i, nameCount = JSPropertyNameArrayGetCount(jsNames);
	// Length of target selector = length of method + length of each (argument + ':')
	int targetSelectorLength = [methodName length];
	// Actual arguments
	JSValueRef*	actualArguments = malloc(sizeof(JSValueRef)*nameCount);
	for (i=0; i<nameCount; i++)
	{
		JSStringRef jsName = JSPropertyNameArrayGetNameAtIndex(jsNames, i);
		id name = (id)JSStringCopyCFString(kCFAllocatorDefault, jsName);
		id nameWithColon = [[NSString stringWithFormat:@"%@:", name] lowercaseString];
		targetSelectorLength += [nameWithColon length];
		[names addObject:nameWithColon];
		[NSMakeCollectable(name) release];
		
		// Get actual argument
		actualArguments[i] = JSObjectGetProperty(c, o, jsName, NULL);
		// NO ! We didn't create it, we don't release it
//		JSStringRelease(jsName);
	}
	JSPropertyNameArrayRelease(jsNames);

	// We'll save the matching selector in this key
	id key = [NSMutableString stringWithFormat:@"%@-", class];
	id sortedNames = [names sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	for (id n in sortedNames)	[key appendString:n];
	key = [key lowercaseString];
	
	// ##todo : actually cache the sel !
	id existingSelector = [splitCallCache objectForKey:key];
	if (existingSelector)
	{
//		NSLog(@"Split call cache hit *%@*%@*", key, existingSelector);
		*_methodName	= existingSelector;
		*_argumentCount	= nameCount;
		*_arguments		= actualArguments;
		return	YES;
	}
	
	
	// Search through every class level
	id lowerCaseMethodName = [methodName lowercaseString];
	while (class)
	{
		// Get method list
		unsigned int methodCount;
		Method* methods = class_copyMethodList(class, &methodCount);

		// Search each method of this level
		for (i=0; i<methodCount; i++)
		{
			Method m = methods[i];
			id name = [NSStringFromSelector(method_getName(m)) lowercaseString];

			// Is this selector's length the same as the one we're searching ?
			if ([name length] == targetSelectorLength)
			{
				char* s = (char*)[name UTF8String];
				const char* t = [lowerCaseMethodName UTF8String];
				int l = strlen(t);
				// Does the selector start with the method name ?
				if (strncmp(s, t, l) == 0)
				{
					s += l;
					// Go through arguments and check if they're part of the string
					int consumedLength = 0;
					for (id n in sortedNames)
					{
						if (strstr(s, [n UTF8String]))	consumedLength += [n length];
					}
					// We've found our selector if we've consumed every argument
					if (consumedLength == strlen(s))
					{
						id selector		= NSStringFromSelector(method_getName(m));
						*_methodName	= selector;
						*_argumentCount	= nameCount;
						*_arguments		= actualArguments;
//						NSLog(@"split call found %s", method_getName(m));

						// Store in split call cache
						[splitCallCache setObject:selector forKey:key];

						free(methods);
						return	YES;
					}
				}
			}
		}
		
		free(methods);
		class = [class superclass];
	}
	free(actualArguments);
	return	NO;
}

/*
	Check if class has a method starting with 'start'
	If YES, it's potentially a split call : we'll return an object in getProperty
	If NO, we'll return NULL in getProperty

*/
+ (BOOL)isMaybeSplitCall:(NSString*)_start forClass:(id)class
{
//	NSLog(@"isMaybeSplitCall=%@.%@ %d", _start, class, class == [class class]);
//	id key = [NSString stringWithFormat:@"%@ %@", [obj class], str];
	int i;

	id start = [_start lowercaseString];
	// Search through every class level
	while (class)
	{
		// Get method list
		unsigned int methodCount;
		Method* methods = class_copyMethodList(class, &methodCount);

//		NSLog(@"isMaybeSplitCall class=%@==============", class);
		// Search each method of this level
		for (i=0; i<methodCount; i++)
		{
			Method m = methods[i];
			id name = [NSStringFromSelector(method_getName(m)) lowercaseString];
//			NSLog(@"isMaybeSplitCall=%@", name);
			if ([name hasPrefix:start])
			{
//				NSLog(@"isMaybeSplitCall FOUND=%@", name);
				free(methods);
				return	YES;
			}
		}
		
		free(methods);
		class = [class superclass];
	}
	return	NO;
}


#pragma mark Variadic call
- (BOOL)isMethodVariadic:(id)methodName class:(id)class
{
	id className = [class description];
	id xml = [[BridgeSupportController sharedController] queryName:className];
	if (!xml)	return NSLog(@"isMethodVariadic for %@ called on unknown BridgeSupport class %@", methodName, class), NO;

	// Get XML definition
	id error;
	id xmlDocument = [[NSXMLDocument alloc] initWithXMLString:xml options:0 error:&error];
	if (error)	return	NSLog(@"(isMethodVariadic:class:) malformed xml while getting method %@ of class %@ : %@", methodName, class, error), NO;
		
	// Query method
	id xpath = [NSString stringWithFormat:@"*[@selector=\"%@\" and @variadic=\"true\"]", methodName];
	id nodes = [[xmlDocument rootElement] nodesForXPath:xpath error:&error];
	if (error)	NSLog(@"isMethodVariadic:error: %@", error);

	// It's a variadic method if XPath returned one result
	BOOL	isVariadic = [nodes count] == 1;
	[xmlDocument release];
	return	isVariadic;
}

- (BOOL)isFunctionVariadic:(id)functionName
{
	id xml = [[BridgeSupportController sharedController] queryName:functionName];

	// Get XML definition
	id error;
	id xmlDocument = [[NSXMLDocument alloc] initWithXMLString:xml options:0 error:&error];
	if (error)	return	NSLog(@"(isMethodVariadic:class:) malformed xml while getting function %@ : %@", functionName, error), NO;

	// Query method
	id xpath = @"//*[@variadic=\"true\"]";
	id nodes = [[xmlDocument rootElement] nodesForXPath:xpath error:&error];
	if (error)	NSLog(@"isMethodVariadic:error: %@", error);

	// It's a variadic method if XPath returned one result
	BOOL	isVariadic = [nodes count] == 1;
	[xmlDocument release];
	return	isVariadic;
}

#pragma mark Boxed object hash

+ (JSObjectRef)boxedJSObject:(id)o inContext:(JSContextRef)ctx
{
	id key = [NSString stringWithFormat:@"%x", o];
	id value = [boxedObjects valueForKey:key];
	// If object is boxed, up its usage count and return it
	if (value)
	{
//		NSLog(@"upusage %@ (rc=%d) %d", o, [o retainCount], [value usageCount]);
		return	[value jsObject];
	}

	//
	// Create a new ObjC box around the JSValueRef boxing the JSObject
	// , so we need to box
	// Here's the why of the boxing :
	// We are returning an ObjC object to Javascript.
	// That ObjC object is boxed in a Javascript object.
	// For all boxing requests of the same ObjC object, that Javascript object needs to be unique for object comparisons to work :
	//		NSApplication.sharedApplication == NSApplication.sharedApplication
	//		(JavascriptCore has no hook for object to object comparison, that's why objects need to be unique)
	// To guarantee unicity, we keep a cache of boxed objects. 
	// As boxed objects are JSObjectRef not derived from NSObject, we box them in an ObjC object.
	//
	
	// Box the ObjC object in a JSObjectRef
	JSObjectRef jsObject = [self jsCocoaPrivateObjectInContext:ctx];
	JSCocoaPrivateObject* private = JSObjectGetPrivate(jsObject);
	private.type = @"@";
	[private setObject:o];
	
	// Box the JSObjectRef in our ObjC object
	value = [[BoxedJSObject alloc] init];
	[value setJSObject:jsObject];

	// Add to dictionary and make it sole owner
	[boxedObjects setValue:value forKey:key];
	[value release];
	return	jsObject;
}


+ (void)downBoxedJSObjectCount:(id)o
{
	id key = [NSString stringWithFormat:@"%x", o];
	id value = [boxedObjects valueForKey:key];
	if (!value)
	{
		NSLog(@"downBoxedJSObjectCount: without an up !");
		NSLog(@"downBoxedJSObjectCount: %@ %x", [o class], o);
		return;
	}
//	NSLog(@"downusage %@ (rc=%d) %d", o, [o retainCount], [value usageCount]);
//	if (count == 0)
	{
//		NSLog(@"CLEAN %@ (%@ rc=%d)", o, value, [value retainCount]);
		[boxedObjects removeObjectForKey:key];
//		NSLog(@"CLEANED ? %x", [boxedObjects valueForKey:key]);
	}
}

+ (id)boxedObjects
{
	return boxedObjects;
}

#pragma mark Helpers
- (id)selectorForJSFunction:(JSObjectRef)function
{
	return [jsFunctionSelectors valueForKey:[NSString stringWithFormat:@"%x", function]];
}

- (id)classForJSFunction:(JSObjectRef)function
{
	return [jsFunctionClasses valueForKey:[NSString stringWithFormat:@"%x", function]];
}

//
// Given an exception, get its line number, source URL, error message and return them in a NSString
//	When throwing an exception from Javascript, throw an object instead of a string. 
//	This way, JavascriptCore will add line and sourceURL.
//	(throw new String('error') instead of throw 'error')
//
- (NSString*)formatJSException:(JSValueRef)exception
{
	// Convert exception to string
	JSStringRef resultStringJS = JSValueToStringCopy(ctx, exception, NULL);
	NSString* b = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, resultStringJS);
	JSStringRelease(resultStringJS);
	[NSMakeCollectable(b) autorelease];

	// Only objects contain line and source URL
	if (JSValueGetType(ctx, exception) != kJSTypeObject)	return	b;

	// Iterate over all properties of the exception
	JSObjectRef jsObject = JSValueToObject(ctx, exception, NULL);
	JSPropertyNameArrayRef jsNames = JSObjectCopyPropertyNames(ctx, jsObject);
	int i, nameCount = JSPropertyNameArrayGetCount(jsNames);
	id line = nil, sourceURL = nil;
	for (i=0; i<nameCount; i++)
	{
		JSStringRef jsName = JSPropertyNameArrayGetNameAtIndex(jsNames, i);
		id name = (id)JSStringCopyCFString(kCFAllocatorDefault, jsName);

		JSValueRef	jsValueRef = JSObjectGetProperty(ctx, jsObject, jsName, NULL);
		JSStringRef	valueJS = JSValueToStringCopy(ctx, jsValueRef, NULL);
		NSString* value = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, valueJS);
		JSStringRelease(valueJS);
		
		if ([name isEqualToString:@"line"])			line = value;
		if ([name isEqualToString:@"sourceURL"])	sourceURL = value;
		[NSMakeCollectable(name) release];
		// Autorelease because we assigned it to line / sourceURL
		[NSMakeCollectable(value) autorelease];
	}
	JSPropertyNameArrayRelease(jsNames);
	return [NSString stringWithFormat:@"%@ on line %@ of %@", b, line, sourceURL];
}

//
// Error reporting
//
- (void) callDelegateForException:(JSValueRef)exception {
    if (!_delegate || ![_delegate respondsToSelector:@selector(JSCocoa:hadError:onLineNumber:atSourceURL:)]) {
        
		NSLog(@"JSException: %@", [self formatJSException:exception]);
        
        return;
    }
    
    JSStringRef resultStringJS = JSValueToStringCopy(ctx, exception, NULL);
	NSString* b = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, resultStringJS);
	JSStringRelease(resultStringJS);
	[NSMakeCollectable(b) autorelease];
    
	if (JSValueGetType(ctx, exception) != kJSTypeObject) {
        [_delegate JSCocoa:self hadError:b onLineNumber:0 atSourceURL:nil];
    }
    
	// Iterate over all properties of the exception
	JSObjectRef jsObject = JSValueToObject(ctx, exception, NULL);
	JSPropertyNameArrayRef jsNames = JSObjectCopyPropertyNames(ctx, jsObject);
	int i, nameCount = JSPropertyNameArrayGetCount(jsNames);
	id line = nil, sourceURL = nil;
	for (i=0; i<nameCount; i++)
	{
		JSStringRef jsName = JSPropertyNameArrayGetNameAtIndex(jsNames, i);
		id name = (id)JSStringCopyCFString(kCFAllocatorDefault, jsName);
        
		JSValueRef	jsValueRef = JSObjectGetProperty(ctx, jsObject, jsName, NULL);
		JSStringRef	valueJS = JSValueToStringCopy(ctx, jsValueRef, NULL);
		NSString* value = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, valueJS);
		JSStringRelease(valueJS);
		
		if ([name isEqualToString:@"line"])			line = value;
		if ([name isEqualToString:@"sourceURL"])	sourceURL = value;
		[NSMakeCollectable(name) release];
		// Autorelease because we assigned it to line / sourceURL
		[NSMakeCollectable(value) autorelease];
	}
	JSPropertyNameArrayRelease(jsNames);
    
    [_delegate JSCocoa:self hadError:b onLineNumber:[line intValue] atSourceURL:sourceURL];
}


#pragma mark Tests
- (BOOL)runTests:(NSString*)path
{
#if defined(TARGET_OS_IPHONE)
#elif defined(TARGET_IPHONE_SIMULATOR)
#else
	id files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
	id predicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH[c] '.js'"];
	files = [files filteredArrayUsingPredicate:predicate]; 
//	NSLog(@"files=%@", files);

	if ([files count] == 0)	return	[JSCocoaController logAndSay:@"no test files found"], NO;
	
	for (id file in files)
	{
		id filePath = [NSString stringWithFormat:@"%@/%@", path, file];
//		NSLog(@">>>evaling %@", filePath);
		BOOL evaled = [self evalJSFile:filePath];
//		NSLog(@">>>EVALED %d, %@", evaled, filePath);
		if (!evaled)	
		{
			id error = [NSString stringWithFormat:@"test %@ failed", file];
			[JSCocoaController logAndSay:error];
			return NO;
		}
		[self garbageCollect];
	}
#endif	
	return	YES;
}

#pragma mark Autorelease pool
static id autoreleasePool;
+ (void)allocAutoreleasePool
{
	autoreleasePool = [[NSAutoreleasePool alloc] init];
}

+ (void)deallocAutoreleasePool
{
	[autoreleasePool release];
}


#pragma mark Garbage Collection
//
// Collect on top of the run loop, not in some JS function
//
+ (void)garbageCollect	{	NSLog(@"***Call garbageCollect on an instance***"); JSGarbageCollect(NULL); }
- (void)garbageCollect	{	JSGarbageCollect(ctx); }

//
// Make all root Javascript variables point to null
//
- (void)unlinkAllReferences
{
	// Null and delete every reference to every live object
//	[self evalJSString:@"for (var i in this) { log('DELETE ' + i); this[i] = null; delete this[i]; }"];
	[self evalJSString:@"for (var i in this) { this[i] = null; delete this[i]; }"];
	// Everything is now collectable !
}

#pragma mark Garbage Collection debug

// Boxing object, set as a Javascript object's private data
static int JSCocoaPrivateObjectCount = 0; 
+ (void)upJSCocoaPrivateObjectCount		{	JSCocoaPrivateObjectCount++;		}
+ (void)downJSCocoaPrivateObjectCount	{	JSCocoaPrivateObjectCount--;		}
+ (int)JSCocoaPrivateObjectCount		{	return	JSCocoaPrivateObjectCount;	}

// Javascript hash, set on classes created with JSCocoaController.createClass
// - used to store js values on instances ( someClassDerivedInJS['someValue'] = 'hello !' )
static int JSCocoaHashCount = 0; 
+ (void)upJSCocoaHashCount				{	JSCocoaHashCount++;					}
+ (void)downJSCocoaHashCount			{	JSCocoaHashCount--;					}
+ (int)JSCocoaHashCount					{	return	JSCocoaHashCount;			}


// Value protect
static int JSValueProtectCount = 0;
+ (void)upJSValueProtectCount			{	JSValueProtectCount++;				}
+ (void)downJSValueProtectCount			{	JSValueProtectCount--;				}
+ (int)JSValueProtectCount				{	return	JSValueProtectCount;		}

// Instance count
int	fullInstanceCount	= 0;
int	liveInstanceCount	= 0;
+ (void)upInstanceCount:(id)o
{
//	NSLog(@"UP %@ %x", o, o);
	fullInstanceCount++;
	liveInstanceCount++;

	id key = [NSMutableString stringWithFormat:@"%@", [o class]];
	
	id existingCount = [sharedInstanceStats objectForKey:key];
	int count = 0;
	if (existingCount)	count = [existingCount intValue];
	
	count++;
	[sharedInstanceStats setObject:[NSNumber numberWithInt:count] forKey:key];
}
+ (void)downInstanceCount:(id)o
{
//	NSLog(@"DOWN %@ %x", o, o);
	liveInstanceCount--;

	id key = [NSMutableString stringWithFormat:@"%@", [o class]];
	
	id existingCount = [sharedInstanceStats objectForKey:key];
	if (!existingCount)
	{
		NSLog(@"downInstanceCount on %@ without any up", o);
		return;
	}
	int count = [existingCount intValue];
	count--;
	
	if (count)	[sharedInstanceStats setObject:[NSNumber numberWithInt:count] forKey:key];
	else		[sharedInstanceStats removeObjectForKey:key];
}
+ (int)liveInstanceCount:(Class)c
{
	id key = [NSMutableString stringWithFormat:@"%@", c];
	
	id existingCount = [sharedInstanceStats objectForKey:key];
	if (!existingCount)	return	0;
	return	[existingCount intValue];
}
+ (id)liveInstanceHash
{
	return	sharedInstanceStats;
}


+ (void)logInstanceStats
{
	id allKeys = [sharedInstanceStats allKeys];
	NSLog(@"====instanceStats : %d classes spawned %d live instances (%d since launch, %d dead)====", [allKeys count], liveInstanceCount, fullInstanceCount, fullInstanceCount-liveInstanceCount);
	for (id key in allKeys)		
		NSLog(@"%@=%d", key, [[sharedInstanceStats objectForKey:key] intValue]);
	if ([allKeys count])	NSLog(@"====");
}


@end







#pragma mark Javascript setter functions
// Hold these methods in a derived NSObject class : only derived classes created with a __jsHash (capable of hosting js objects) will get them
@interface	JSCocoaMethodHolder : NSObject
@end
// Stored there for convenience. They won't be used by JSCocoaPrivateObject but will be patched in for any derived class
@implementation JSCocoaMethodHolder
- (BOOL)setJSValue:(JSValueRefAndContextRef)valueAndContext forJSName:(JSValueRefAndContextRef)nameAndContext
{
	if (class_getInstanceVariable([self class], "__jsHash"))
	{
		JSContextRef c = valueAndContext.ctx;
		JSStringRef name = JSValueToStringCopy(c, nameAndContext.value, NULL);

		JSObjectRef hash = NULL;
		object_getInstanceVariable(self, "__jsHash", (void**)&hash);
		if (!hash)
		{
			// Retrieve controller
			id jsc = [JSCocoaController controllerFromContext:c];
			c = [jsc ctx];

			hash = JSObjectMake(c, hashObjectClass, NULL);
			object_setInstanceVariable(self, "__jsHash", (void*)hash);
			object_setInstanceVariable(self, "__jsCocoaController", (void*)jsc);
			JSValueProtect(c, hash);
			[JSCocoaController upJSValueProtectCount];
			[JSCocoaController upJSCocoaHashCount];
		}
	
//		NSLog(@"SET JS VALUE %x %@", valueAndContext.value, [(id)JSStringCopyCFString(kCFAllocatorDefault, name) autorelease]);
		JSObjectSetProperty(c, hash, name, valueAndContext.value, kJSPropertyAttributeNone, NULL);
		JSStringRelease(name);
		return	YES;
	}
	return	NO;
}
- (JSValueRefAndContextRef)JSValueForJSName:(JSValueRefAndContextRef)nameAndContext
{
	JSValueRefAndContextRef valueAndContext = { JSValueMakeNull(nameAndContext.ctx), NULL };
	if (class_getInstanceVariable([self class], "__jsHash"))
	{
		JSContextRef c = nameAndContext.ctx;
		JSStringRef name = JSValueToStringCopy(c, nameAndContext.value, NULL);
	
		JSObjectRef hash = NULL;
		object_getInstanceVariable(self, "__jsHash", (void**)&hash);
		if (!hash || !JSObjectHasProperty(c, hash, name))	
		{
			JSStringRelease(name);
			return	valueAndContext;
		}

		valueAndContext.ctx		= c;
		valueAndContext.value	= JSObjectGetProperty(c, hash, name, NULL);
		JSStringRelease(name);
		return	valueAndContext;
	}
	return	valueAndContext;
}

- (BOOL)deleteJSValueForJSName:(JSValueRefAndContextRef)nameAndContext
{
	if (class_getInstanceVariable([self class], "__jsHash"))
	{
		JSContextRef c = nameAndContext.ctx;
		JSStringRef name = JSValueToStringCopy(c, nameAndContext.value, NULL);
	
		JSObjectRef hash = NULL;
		object_getInstanceVariable(self, "__jsHash", (void**)&hash);
		if (!hash || !JSObjectHasProperty(c, hash, name))	
		{
			JSStringRelease(name);
			return	NO;
		}
		bool r =	JSObjectDeleteProperty(c, hash, name, NULL);
		JSStringRelease(name);

		return	r;
	}
	return	NO;
}


// Instance count debug
+ (id)allocWithZone:(NSZone*)zone
{
	// Dynamic super call
	id parentClass = [JSCocoaController parentObjCClassOfClassName:[NSString stringWithUTF8String:class_getName(self)]];
	id supermetaclass = objc_getMetaClass(class_getName(parentClass));
	struct objc_super superData = { self, supermetaclass };
	id o = objc_msgSendSuper(&superData, @selector(allocWithZone:), zone);

	[JSCocoaController upInstanceCount:o];
	return	o;
}

// Dealloc : unprotect js hash
- (void)deallocAndCleanupJS
{
	JSObjectRef hash = NULL;
	object_getInstanceVariable(self, "__jsHash", (void**)&hash);
	if (hash)	
	{
		id jsc = NULL;
		object_getInstanceVariable(self, "__jsCocoaController", (void**)&jsc);
//JSContextRef context;
//		object_getInstanceVariable(self, "__jsCocoaController", (void**)&context);
		JSValueUnprotect([jsc ctx], hash);
//		JSValueUnprotect(context, hash);
		[JSCocoaController downJSCocoaHashCount];
	}
	[JSCocoaController downInstanceCount:self];

	// Dynamic super call
	id parentClass = [JSCocoaController parentObjCClassOfClassName:[NSString stringWithUTF8String:class_getName([self class])]];
	struct objc_super superData = { self, parentClass };
	objc_msgSendSuper(&superData, @selector(dealloc));
}

// Finalize - same as dealloc
- (void)finalize
{
	JSObjectRef hash = NULL;
	object_getInstanceVariable(self, "__jsHash", (void**)&hash);
	if (hash)	
	{
		id jsc = NULL;
		object_getInstanceVariable(self, "__jsCocoaController", (void**)&jsc);
		JSValueUnprotect([jsc ctx], hash);
		[JSCocoaController downJSCocoaHashCount];
	}
	[JSCocoaController downInstanceCount:self];

	// Dynamic super call
	id parentClass = [JSCocoaController parentObjCClassOfClassName:[NSString stringWithUTF8String:class_getName([self class])]];
	struct objc_super superData = { self, parentClass };
	objc_msgSendSuper(&superData, @selector(finalize));
	
	// Ignore warning about missing [super finalize] as the call IS made via objc_msgSendSuper
}


@end


#pragma mark Common instance method
// Class.instance == class.alloc.init + release (jsObject retains object)
// Class.instance( { withA : ... andB : ... } ) == class.alloc.initWithA:... andB:... + release
@implementation NSObject(CommonInstance)
+ (JSValueRef)instanceWithContext:(JSContextRef)ctx argumentCount:(size_t)argumentCount arguments:(JSValueRef*)arguments exception:(JSValueRef*)exception
{
	id methodName  = @"init";
	JSValueRef*	argumentsToFree = NULL;
	// Recover init method
	if (argumentCount == 1)
	{
		id	splitMethodName				= @"init";
		BOOL isSplitCall = [JSCocoaController trySplitCall:&splitMethodName class:self argumentCount:&argumentCount arguments:&arguments ctx:ctx];
		if (isSplitCall)	
		{
			methodName		= splitMethodName;
			argumentsToFree	= arguments;
		}
		else				return	throwException(ctx, exception, @"Instance split call did not find an init method"), NULL;
	}
//	NSLog(@"=>Called instance on %@ with init=%@", self, methodName);

	// Allocate new instance
	id newInstance = [self alloc];
	
/*	
	// Set it as new object
	JSObjectRef thisObject = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
	JSCocoaPrivateObject* private = JSObjectGetPrivate(thisObject);
	private.type = @"@";
	[private setObject:newInstance];
*/
	JSObjectRef thisObject = [JSCocoaController boxedJSObject:newInstance inContext:ctx];
	
	// Create function object boxing our init method
	JSObjectRef function = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
	JSCocoaPrivateObject* private = JSObjectGetPrivate(function);
	private.type = @"method";
	private.methodName = methodName;

	// Call callAsFunction on our new instance with our init method
	JSValueRef exceptionFromInitCall = NULL;
	JSValueRef returnValue = jsCocoaObject_callAsFunction(ctx, function, thisObject, argumentCount, arguments, &exceptionFromInitCall);
	free(argumentsToFree);
	if (exceptionFromInitCall)	return	*exception = exceptionFromInitCall, NULL;
	
	// Release object
	JSObjectRef returnObject = JSValueToObject(ctx, returnValue, NULL);
	// We can get nil when initWith... fails. (eg var image = NSImage.instance({withContentsOfFile:'DOESNOTEXIST'})
	// Return nil then.
	if (returnObject == nil)	return	JSValueMakeNull(ctx);
	private = JSObjectGetPrivate(returnObject);
	[[private object] release];
	
//	NSLog(@"returnValue from instanceWithContext=%x", returnValue);
	return	returnValue;
}
@end






#pragma mark JS OSX object

//
//
//	Global resolver
//
//



JSValueRef OSXObject_getProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef* exception)
{
	NSString*	propertyName = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, propertyNameJS);
	[NSMakeCollectable(propertyName) autorelease];
	
	if ([propertyName isEqualToString:@"__jsc__"])	return	NULL;
	
//	NSLog(@"Asking for global property %@", propertyName);
	JSCocoaController* jsc = [JSCocoaController controllerFromContext:ctx];
	id delegate = jsc.delegate;
	//
	// Delegate canGetGlobalProperty, getGlobalProperty
	//
	if (delegate)
	{
		// Check if getting is allowed
		if ([delegate respondsToSelector:@selector(JSCocoa:canGetGlobalProperty:inContext:exception:)])
		{
			BOOL canGetGlobal = [delegate JSCocoa:jsc canGetGlobalProperty:propertyName inContext:ctx exception:exception];
			if (!canGetGlobal)
			{
				if (!*exception)	throwException(ctx, exception, [NSString stringWithFormat:@"Delegate does not allow getting global property %@", propertyName]);
				return	NULL;
			}
		}
		// Check if delegate handles getting
		if ([delegate respondsToSelector:@selector(JSCocoa:getGlobalProperty:inContext:exception:)])
		{
			JSValueRef delegateGetGlobal = [delegate JSCocoa:jsc getGlobalProperty:propertyName inContext:ctx exception:exception];
			if (delegateGetGlobal)		return	delegateGetGlobal;
		}
	}
	
	//
	// ObjC class
	//
	Class objCClass = NSClassFromString(propertyName);
	if (objCClass && ![propertyName isEqualToString:@"Object"])
	{
		JSValueRef ret = [JSCocoaController boxedJSObject:objCClass inContext:ctx];
		return	ret;
	}

	id xml;
	id type = nil;
	//
	// Query BridgeSupport for property
	//
	xml = [[BridgeSupportController sharedController] queryName:propertyName];
	if (xml)
	{
		id error = nil;
		id xmlDocument = [[NSXMLDocument alloc] initWithXMLString:xml options:0 error:&error];
		if (error)	return	NSLog(@"(OSX_getPropertyCallback) malformed xml while getting property %@ of type %@ : %@", propertyName, type, error), NULL;
		[xmlDocument autorelease];
		
		type = [[xmlDocument rootElement] name];

		//
		// Function
		//
		if ([type isEqualToString:@"function"])
		{
			JSObjectRef o = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
			JSCocoaPrivateObject* private = JSObjectGetPrivate(o);
			private.type = @"function";
			private.xml = xml;
			return	o;
		}

		//
		// Struct
		//
		else
		if ([type isEqualToString:@"struct"])
		{
			JSObjectRef o = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
			JSCocoaPrivateObject* private = JSObjectGetPrivate(o);
			private.type = @"struct";
			private.xml = xml;
			return	o;
		}
		
		//
		// Constant
		//
		else
		if ([type isEqualToString:@"constant"])
		{
			// Check if constant's declared_type is NSString*
			id declared_type = [[xmlDocument rootElement] attributeForName:@"declared_type"];
			if (!declared_type)	declared_type = [[xmlDocument rootElement] attributeForName:@"type"];
			if (!declared_type || !([[declared_type stringValue] isEqualToString:@"NSString*"] 
									|| [[declared_type stringValue] isEqualToString:@"@"]
									|| [[declared_type stringValue] isEqualToString:@"^{__CFString=}"]
									))	
				return	NSLog(@"(OSX_getPropertyCallback) %@ not a NSString* constant : %@", propertyName, xml), NULL;

			// Grab symbol
			void* symbol = dlsym(RTLD_DEFAULT, [propertyName UTF8String]);
			if (!symbol)	return	NSLog(@"(OSX_getPropertyCallback) symbol %@ not found", propertyName), NULL;
			NSString* str = *(NSString**)symbol;

			// Return symbol as a Javascript string
			JSStringRef jsName = JSStringCreateWithUTF8CString([str UTF8String]);
			JSValueRef jsString = JSValueMakeString(ctx, jsName);
			JSStringRelease(jsName);
			return	jsString;
		}

		//
		// Enum
		//
		else
		if ([type isEqualToString:@"enum"])
		{
			// Check if constant's declared_type is NSString*
			id value = [[xmlDocument rootElement] attributeForName:@"value"];
			if (!value)	return	NSLog(@"(OSX_getPropertyCallback) %@ enum has no value set", propertyName), NULL;

			// Try parsing value
			double doubleValue = 0;
			value = [value stringValue];
			if (![[NSScanner scannerWithString:value] scanDouble:&doubleValue]) return	NSLog(@"(OSX_getPropertyCallback) scanning %@ enum failed", propertyName), NULL;
			return	JSValueMakeNumber(ctx, doubleValue);
		}
	}
	return	NULL;
}









#pragma mark JSCocoa object


//
// From PyObjC : when to call objc_msgSendStret, for structure return
//		Depending on structure size & architecture, structures are returned as function first argument (done transparently by ffi) or via registers
//
BOOL	isUsingStret(id argumentEncodings)
{
	int resultSize = 0;
	char returnEncoding = [[argumentEncodings objectAtIndex:0] typeEncoding];
	if (returnEncoding == _C_STRUCT_B) resultSize = [JSCocoaFFIArgument sizeOfStructure:[[argumentEncodings objectAtIndex:0] structureTypeEncoding]];
	if (returnEncoding == _C_STRUCT_B && 
	//#ifdef  __ppc64__
	//			ffi64_stret_needs_ptr(signature_to_ffi_return_type(rettype), NULL, NULL)
	//
	//#else /* !__ppc64__ */
				(resultSize > SMALL_STRUCT_LIMIT
	#ifdef __i386__
				 /* darwin/x86 ABI is slightly odd ;-) */
				 || (resultSize != 1 
					&& resultSize != 2 
					&& resultSize != 4 
					&& resultSize != 8)
	#endif
	#ifdef __x86_64__
				 /* darwin/x86-64 ABI is slightly odd ;-) */
				 || (resultSize != 1 
					&& resultSize != 2 
					&& resultSize != 4 
					&& resultSize != 8
					&& resultSize != 16
					)
	#endif
				)
	//#endif /* !__ppc64__ */
				) {
//					callAddress = objc_msgSend_stret;
//					usingStret = YES;
				return	YES;
			}
		return	NO;				
}

//
// Autocall : return value
//
JSValueRef valueOfCallback(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception)
{
	// Holding a native JS value ? Return it
	JSCocoaPrivateObject* thisPrivateObject = JSObjectGetPrivate(thisObject);
	if ([thisPrivateObject.type isEqualToString:@"jsValueRef"])	
	{
		return [thisPrivateObject jsValueRef];
	}
	
	// NSNumber special case
	if ([thisPrivateObject.object isKindOfClass:[NSNumber class]])
		return	JSValueMakeNumber(ctx, [thisPrivateObject.object doubleValue]);

	// Convert to string
	id toString = [NSString stringWithFormat:@"JSCocoaPrivateObject type=%@", thisPrivateObject.type];
	
	// Object
	if ([thisPrivateObject.type isEqualToString:@"@"])
	{
		// Holding an out value ?
		if ([thisPrivateObject.object isKindOfClass:[JSCocoaOutArgument class]])
		{
			JSValueRef outValue = [(JSCocoaOutArgument*)thisPrivateObject.object outJSValueRefInContext:ctx];
			// Holding an object ? Call valueOf on it
			if (JSValueGetType(ctx, outValue) == kJSTypeObject)
				return	valueOfCallback(ctx, NULL, JSValueToObject(ctx, outValue, NULL), 0, NULL, NULL);
			// Return raw JSValueRef
			return outValue;
		}
		else
		
			toString = [NSString stringWithFormat:@"%@", [[thisPrivateObject object] description]];
	}

	// Struct
	if ([thisPrivateObject.type isEqualToString:@"struct"])
	{
		id structDescription = nil;
		id self = [JSCocoaController controllerFromContext:ctx];

		if ([self hasJSFunctionNamed:@"describeStruct"])
		{

			JSStringRef scriptJS = JSStringCreateWithUTF8CString("return describeStruct(arguments[0])");
			JSObjectRef fn = JSObjectMakeFunction(ctx, NULL, 0, NULL, scriptJS, NULL, 1, NULL);
			JSValueRef jsValue = JSObjectCallAsFunction(ctx, fn, NULL, 1, (JSValueRef*)&thisObject, NULL);
			JSStringRelease(scriptJS);

			[JSCocoaFFIArgument unboxJSValueRef:jsValue toObject:&structDescription inContext:ctx];

		}
		
		toString = [NSString stringWithFormat:@"<%@ %@>", thisPrivateObject.structureName, structDescription];

	}

	// Convert to string and return
	JSStringRef jsToString = JSStringCreateWithCFString((CFStringRef)toString);
	JSValueRef jsValueToString = JSValueMakeString(ctx, jsToString);
	JSStringRelease(jsToString);
	return	jsValueToString;
}

//
// initialize
//	retain boxed object
//
static void jsCocoaObject_initialize(JSContextRef ctx, JSObjectRef object)
{
	id o = JSObjectGetPrivate(object);
	[o retain];
}

//
// finalize
//	release boxed object
//
static void jsCocoaObject_finalize(JSObjectRef object)
{
	// if dealloc is overloaded, releasing now will trigger JS code and fail
	// As we're being called by GC, KJS might assert() in operationInProgress == NoOperation
	id private = JSObjectGetPrivate(object);
//	NSLog(@"FINALIZING JSOBJECTREF %x holding %@", object, private);
	// Immediate release if dealloc is not overloaded
	[private release];
#ifdef __OBJC_GC__
	// Mark internal object as collectable
	[[NSGarbageCollector defaultCollector] enableCollectorForPointer:private];
#endif
}


//
// getProperty
//	Return property in object's internal Javascript hash if its contains propertyName
//	else ...
//	Get objC method matching propertyName, autocall it
//	else ...
//	method may be a split call -> return a private object
//
//	At method start, handle special cases for arrays (integers, length) and dictionaries
//
static JSValueRef jsCocoaObject_getProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef* exception)
{
	NSString*	propertyName = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, propertyNameJS);
	[NSMakeCollectable(propertyName) autorelease];
	
	// Autocall instance
	if ([propertyName isEqualToString:@"thisObject"])	return	NULL;
	
	JSCocoaPrivateObject* privateObject = JSObjectGetPrivate(object);
//	NSLog(@"Asking for property %@ %@(%@)", propertyName, privateObject, privateObject.type);

	// Get delegate
	JSCocoaController* jsc = [JSCocoaController controllerFromContext:ctx];
	id delegate = jsc.delegate;

	if ([privateObject.type isEqualToString:@"@"])
	{
		//
		// Delegate canGetProperty, getProperty
		//
		if (delegate)
		{
			// Check if getting is allowed
			if ([delegate respondsToSelector:@selector(JSCocoa:canGetProperty:ofObject:inContext:exception:)])
			{
				BOOL canGet = [delegate JSCocoa:jsc canGetProperty:propertyName ofObject:privateObject.object inContext:ctx exception:exception];
				if (!canGet)
				{
					if (!*exception)	throwException(ctx, exception, [NSString stringWithFormat:@"Delegate does not allow getting %@.%@", privateObject.object, propertyName]);
					return	NULL;
				}
			}
			// Check if delegate handles getting
			if ([delegate respondsToSelector:@selector(JSCocoa:getProperty:ofObject:inContext:exception:)])
			{
				JSValueRef delegateGet = [delegate JSCocoa:jsc getProperty:propertyName ofObject:privateObject.object inContext:ctx exception:exception];
				if (delegateGet)		return	delegateGet;
			}
		}

		// Special case for NSMutableArray get
		if ([privateObject.object isKindOfClass:[NSArray class]])
		{
			id array	= privateObject.object;
			id scan		= [NSScanner scannerWithString:propertyName];
			NSInteger propertyIndex;
			// Is asked property an int ?
			BOOL convertedToInt =  ([scan scanInteger:&propertyIndex]);
			if (convertedToInt && [scan isAtEnd])
			{
				if (propertyIndex < 0 || propertyIndex >= [array count])	return	NULL;
				
				id o = [array objectAtIndex:propertyIndex];
				JSValueRef value = NULL;
				[JSCocoaFFIArgument boxObject:o toJSValueRef:&value inContext:ctx];
				return	value;
			}
			
			// If we have 'length', switch it to 'count'
			if ([propertyName isEqualToString:@"length"])	propertyName = @"count";
		}
		
		
		// Special case for NSMutableDictionary get
		if ([privateObject.object isKindOfClass:[NSDictionary class]])
		{
			id dictionary	= privateObject.object;
			id o = [dictionary objectForKey:propertyName];
			if (o)
			{
				JSValueRef value = NULL;
				[JSCocoaFFIArgument boxObject:o toJSValueRef:&value inContext:ctx];
				return	value;
			}
		}

		// Special case for JSCocoaMemoryBuffer get
		if ([privateObject.object isKindOfClass:[JSCocoaMemoryBuffer class]])
		{
			id buffer = privateObject.object;
			
			id scan		= [NSScanner scannerWithString:propertyName];
			NSInteger propertyIndex;
			// Is asked property an int ?
			BOOL convertedToInt =  ([scan scanInteger:&propertyIndex]);
			if (convertedToInt && [scan isAtEnd])
			{
				if (propertyIndex < 0 || propertyIndex >= [buffer typeCount])	return	NULL;
				return	[buffer valueAtIndex:propertyIndex inContext:ctx];
			}
		}
		
		// Check object's internal property in its jsHash
		id callee	= [privateObject object];
		if ([callee respondsToSelector:@selector(JSValueForJSName:)])
		{
			JSValueRefAndContextRef	name	= { JSValueMakeString(ctx, propertyNameJS), ctx } ;
			JSValueRef hashProperty			= [callee JSValueForJSName:name].value;
			if (hashProperty && !JSValueIsNull(ctx, hashProperty))
			{
				return	hashProperty;
			}
		}

		
		//
		// Attempt Zero arg autocall
		// Object.alloc().init() -> Object.alloc.init
		//
		if (useAutoCall)
		{
			id callee	= [privateObject object];
			SEL sel		= NSSelectorFromString(propertyName);
			// Go for zero arg call
			if ([propertyName rangeOfString:@":"].location == NSNotFound && [callee respondsToSelector:sel])
			{
				//
				// Delegate canCallMethod, callMethod
				//
				if (delegate)
				{
					// Check if calling is allowed
					if ([delegate respondsToSelector:@selector(JSCocoa:canCallMethod:ofObject:argumentCount:arguments:inContext:exception:)])
					{
						BOOL canCall = [delegate JSCocoa:jsc canCallMethod:propertyName ofObject:callee argumentCount:0 arguments:NULL inContext:ctx exception:exception];
						if (!canCall)
						{
							if (!*exception)	throwException(ctx, exception, [NSString stringWithFormat:@"Delegate does not allow calling [%@ %@]", callee, propertyName]);
							return	NULL;
						}
					}
					// Check if delegate handles calling
					if ([delegate respondsToSelector:@selector(JSCocoa:callMethod:ofObject:argumentCount:arguments:inContext:exception:)])
					{
						JSValueRef delegateCall = [delegate JSCocoa:jsc callMethod:propertyName ofObject:callee argumentCount:0 arguments:NULL inContext:ctx exception:exception];
						if (delegateCall)	
							return	delegateCall;
					}
				}

				// Special case for alloc : objects 
				if ([propertyName isEqualToString:@"alloc"])
				{
					id allocatedObject = [callee alloc];
					JSObjectRef jsObject = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
					JSCocoaPrivateObject* private = JSObjectGetPrivate(jsObject);
					private.type = @"@";
					[private setObjectNoRetain:allocatedObject];
					return	jsObject;
				}
			
				Method method = class_getInstanceMethod([callee class], sel);
				if (!method)	method = class_getClassMethod([callee class], sel);

				// Extract arguments
				const char* typeEncoding = method_getTypeEncoding(method);
				id argumentEncodings = [JSCocoaController parseObjCMethodEncoding:typeEncoding];
				//
				// From PyObjC : when to call objc_msgSendStret, for structure return
				//		Depending on structure size & architecture, structures are returned as function first argument (done transparently by ffi) or via registers
				//
				BOOL	usingStret = isUsingStret(argumentEncodings);
				void* callAddress = objc_msgSend;
				if (usingStret)	callAddress = objc_msgSend_stret;
				
				//
				// ffi data
				//
				ffi_cif		cif;
				ffi_type*	args[2];
				void*		values[2];
				char*		selector;
	
				selector	= (char*)NSSelectorFromString(propertyName);
				args[0]		= &ffi_type_pointer;
				args[1]		= &ffi_type_pointer;
				values[0]	= (void*)&callee;
				values[1]	= (void*)&selector;
				
				// Get return value holder
				id returnValue = [argumentEncodings objectAtIndex:0];

				// Setup ffi
				ffi_status prep_status	= ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 2, [returnValue ffi_type], args);
				//
				// Call !
				//
				if (prep_status == FFI_OK)
				{
					void* storage = [returnValue storage];
					if ([returnValue ffi_type] == &ffi_type_void)	storage = NULL;
					ffi_call(&cif, callAddress, storage, values);
				}

				// Return now if our function returns void
				// NO - box it
//				if ([returnValue ffi_type] == &ffi_type_void)	return	NULL;
				// Else, convert return value
				JSValueRef	jsReturnValue = NULL;
				BOOL converted = [returnValue toJSValueRef:&jsReturnValue inContext:ctx];
				if (!converted)	return	throwException(ctx, exception, [NSString stringWithFormat:@"Return value not converted in %@", propertyName]), NULL;

				return	jsReturnValue;
			}
		}
		
		// Check if we're holding an out value
		if ([privateObject.object isKindOfClass:[JSCocoaOutArgument class]])
		{
			JSValueRef outValue = [(JSCocoaOutArgument*)privateObject.object outJSValueRefInContext:ctx];
			if (outValue && JSValueGetType(ctx, outValue) == kJSTypeObject)
			{
				JSObjectRef outObject = JSValueToObject(ctx, outValue, NULL);
				JSValueRef possibleReturnValue = JSObjectGetProperty(ctx, outObject, propertyNameJS, NULL);
				return	possibleReturnValue;
			}
		}

		//
		// Do some filtering here on property name : 
		//	We're asked a property name and at this point we've checked the class's jsarray, autocall. 
		//	If the property we're asked does not start a split call we'll return NULL.
		//
		//		Check if the property is actually a method.
		//		If NO, replace underscores with colons
		//				add a ':' suffix
		//
		//		If callee still fails to responds to that, check if propertyName maybe starts a split call.
		//		If NO, return null
		//
		id methodName = [NSMutableString stringWithString:propertyName];
		// If responds to selector, OK
		if (![callee respondsToSelector:NSSelectorFromString(methodName)] 
			// non ObjC methods
			&& ![methodName isEqualToString:@"valueOf"] 
			&& ![methodName isEqualToString:@"Super"]
			&& ![methodName isEqualToString:@"instance"])
		{
			if ([methodName rangeOfString:@"_"].location != NSNotFound)
				[methodName replaceOccurrencesOfString:@"_" withString:@":" options:0 range:NSMakeRange(0, [methodName length])];

			if (![methodName hasSuffix:@":"])	[methodName appendString:@":"];			

			if (![callee respondsToSelector:NSSelectorFromString(methodName)])
			{
				//
				// This may be a JS function
				//
				Class class = [callee class];
				JSValueRef result = NULL;
				while (class)
				{
					id script = [NSString stringWithFormat:@"__globalJSFunctionRepository__.%@.%@", class, propertyName];
					JSStringRef	jsScript = JSStringCreateWithUTF8CString([script UTF8String]);
					result = JSEvaluateScript(ctx, jsScript, NULL, NULL, 1, NULL);
					JSStringRelease(jsScript);
					// Found ? Break
					if (result && JSValueGetType(ctx, result) == kJSTypeObject)	break;
					
					// Go up parent class
					class = [class superclass];
				}
				// This is a pure JS function call — box it
				if (result && JSValueGetType(ctx, result) == kJSTypeObject)
				{
					JSObjectRef o = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
					JSCocoaPrivateObject* private = JSObjectGetPrivate(o);
					private.type = @"jsFunction";
					[private setJSValueRef:result ctx:ctx];
					return	o;
				}

				methodName = propertyName;

				// Get the meta class if callee is a class
				class = [callee class];
				if (callee == class)
					class = objc_getMetaClass(object_getClassName(class));
				// Try split start
				BOOL isMaybeSplit = [JSCocoaController isMaybeSplitCall:methodName forClass:class];
				// If not split and not NSString, return (if NSString, try to convert to JS string in callAsFunction and use native JS methods)
				if (!isMaybeSplit && ![callee isKindOfClass:[NSString class]])	
				{
					return	NULL;
				}
			}
		}

		// Get ready for method call
		JSObjectRef o = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
		JSCocoaPrivateObject* private = JSObjectGetPrivate(o);
		private.type = @"method";
		private.methodName = methodName;

		// Special case for instance : setup a valueOf callback calling instance
		if ([callee class] == callee && [propertyName isEqualToString:@"instance"])
		{
			JSStringRef jsName = JSStringCreateWithUTF8CString("thisObject");
			JSObjectSetProperty(ctx, o, jsName, object, JSCocoaInternalAttribute, NULL);
			JSStringRelease(jsName);
		}
		return	o;
	}

	// Struct valueOf
	if ([privateObject.type isEqualToString:@"struct"] && [propertyName isEqualToString:@"valueOf"])
	{
		JSObjectRef o = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
		JSCocoaPrivateObject* private = JSObjectGetPrivate(o);
		private.type = @"method";
		private.methodName = propertyName;
		return	o;
	}
	
	// Structs will get here when being asked javascript attributes (eg 'x' in point.x)
//	NSLog(@"Asking for property %@ %@(%@)", propertyName, privateObject, privateObject.type);
	
	return	NULL;
}


//
// setProperty
//	call setter : propertyName -> setPropertyName
//
static bool jsCocoaObject_setProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef jsValue, JSValueRef* exception)
{
	JSCocoaPrivateObject* privateObject = JSObjectGetPrivate(object);
	NSString*	propertyName = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, propertyNameJS);
	[NSMakeCollectable(propertyName) autorelease];
	
//	NSLog(@"****SET %@ in ctx %x on object %x (type=%@) method=%@", propertyName, ctx, object, privateObject.type, privateObject.methodName);


	// Get delegate
	JSCocoaController* jsc = [JSCocoaController controllerFromContext:ctx];
	id delegate = jsc.delegate;

	if ([privateObject.type isEqualToString:@"@"])
	{
		//
		// Delegate canSetProperty, setProperty
		//
		if (delegate)
		{
			// Check if setting is allowed
			if ([delegate respondsToSelector:@selector(JSCocoa:canSetProperty:ofObject:toValue:inContext:exception:)])
			{
				BOOL canSet = [delegate JSCocoa:jsc canSetProperty:propertyName ofObject:privateObject.object toValue:jsValue inContext:ctx exception:exception];
				if (!canSet)
				{
					if (!*exception)	throwException(ctx, exception, [NSString stringWithFormat:@"Delegate does not allow setting %@.%@", privateObject.object, propertyName]);
					return	NULL;
				}
			}
			// Check if delegate handles getting
			if ([delegate respondsToSelector:@selector(JSCocoa:setProperty:ofObject:toValue:inContext:exception:)])
			{
				BOOL delegateSet = [delegate JSCocoa:jsc setProperty:propertyName ofObject:privateObject.object toValue:jsValue inContext:ctx exception:exception];
				if (delegateSet)	return	true;
			}
		}

		// Special case for NSMutableArray set
		if ([privateObject.object isKindOfClass:[NSArray class]])
		{
			id array	= privateObject.object;
			if (![array respondsToSelector:@selector(replaceObjectAtIndex:withObject:)])	return	throwException(ctx, exception, @"Calling set on a non mutable array"), false;
			id scan		= [NSScanner scannerWithString:propertyName];
			NSInteger propertyIndex;
			// Is asked property an int ?
			BOOL convertedToInt =  ([scan scanInteger:&propertyIndex]);
			if (convertedToInt && [scan isAtEnd])
			{
				if (propertyIndex < 0 || propertyIndex >= [array count])	return	false;

				id property = NULL;
				if ([JSCocoaFFIArgument unboxJSValueRef:jsValue toObject:&property inContext:ctx])
				{
					[array replaceObjectAtIndex:propertyIndex withObject:property];
					return	true;
				}
				else	return false;
			}
		}


		// Special case for NSMutableDictionary set
		if ([privateObject.object isKindOfClass:[NSDictionary class]])
		{
			id dictionary	= privateObject.object;
			if (![dictionary respondsToSelector:@selector(setObject:forKey:)])	return	throwException(ctx, exception, @"Calling set on a non mutable dictionary"), false;

			id property = NULL;
			if ([JSCocoaFFIArgument unboxJSValueRef:jsValue toObject:&property inContext:ctx])
			{
				[dictionary setObject:property forKey:propertyName];
				return	true;
			}
			else	return false;
		}

		
		// Special case for JSCocoaMemoryBuffer get
		if ([privateObject.object isKindOfClass:[JSCocoaMemoryBuffer class]])
		{
			id buffer = privateObject.object;
			
			id scan		= [NSScanner scannerWithString:propertyName];
			NSInteger propertyIndex;
			// Is asked property an int ?
			BOOL convertedToInt =  ([scan scanInteger:&propertyIndex]);
			if (convertedToInt && [scan isAtEnd])
			{
				if (propertyIndex < 0 || propertyIndex >= [buffer typeCount])	return	NULL;
				return	[buffer setValue:jsValue atIndex:propertyIndex inContext:ctx];
			}
		}
		
		
		
		// Try shorthand overload : obc[selector] = function
		id callee	= [privateObject object];
		if ([propertyName rangeOfString:@":"].location != NSNotFound)
		{
			JSValueRefAndContextRef v = { jsValue, ctx };
			[JSCocoaController overloadInstanceMethod:propertyName class:[callee class] jsFunction:v];
			return	true;
		}
		
		
		// Can't use capitalizedString on the whole string as it will transform 
		//			myValue 
		// to		Myvalue (therby destroying camel letters)
		// we want	MyValue
//		NSString*	setterName = [NSString stringWithFormat:@"set%@:", [propertyName capitalizedString]];
		// Capitalize only first letter
		NSString*	setterName = [NSString stringWithFormat:@"set%@%@:", 
											[[propertyName substringWithRange:NSMakeRange(0,1)] capitalizedString], 
											[propertyName substringWithRange:NSMakeRange(1, [propertyName length]-1)]];

//		NSLog(@"SETTING %@ %@", propertyName, setterName);
		
		//
		// Attempt Zero arg autocall for setter
		// Object.alloc().init() -> Object.alloc.init
		//
		SEL sel		= NSSelectorFromString(setterName);
		if ([callee respondsToSelector:sel])
		{
			//
			// Delegate canCallMethod, callMethod
			//
			if (delegate)
			{
				// Check if calling is allowed
				if ([delegate respondsToSelector:@selector(JSCocoa:canCallMethod:ofObject:argumentCount:arguments:inContext:exception:)])
				{
					BOOL canCall = [delegate JSCocoa:jsc canCallMethod:setterName ofObject:callee argumentCount:0 arguments:NULL inContext:ctx exception:exception];
					if (!canCall)
					{
						if (!*exception)	throwException(ctx, exception, [NSString stringWithFormat:@"Delegate does not allow calling [%@ %@]", callee, setterName]);
						return	NULL;
					}
				}
				// Check if delegate handles calling
				if ([delegate respondsToSelector:@selector(JSCocoa:callMethod:ofObject:argumentCount:arguments:inContext:exception:)])
				{
					JSValueRef delegateCall = [delegate JSCocoa:jsc callMethod:setterName ofObject:callee argumentCount:0 arguments:NULL inContext:ctx exception:exception];
					if (delegateCall)	return	!!delegateCall;
				}
			}

			Method method = class_getInstanceMethod([callee class], sel);
			if (!method)	method = class_getClassMethod([callee class], sel);
/*
			// NSDistantObject
            if (!method && [callee methodSignatureForSelector:NSSelectorFromString(setterName)]) {
                return _jsCocoaObject_callUsingNSInvocation(ctx, callee, setterName, 0, nil);
            }			
*/
			// Extract arguments
			const char* typeEncoding = method_getTypeEncoding(method);
			id argumentEncodings = [JSCocoaController parseObjCMethodEncoding:typeEncoding];
			if ([[argumentEncodings objectAtIndex:0] typeEncoding] != 'v')	return	throwException(ctx, exception, [NSString stringWithFormat:@"(in setter) %@ must return void", setterName]), false;

			//
			// From PyObjC : when to call objc_msgSendStret, for structure return
			//		Depending on structure size & architecture, structures are returned as function first argument (done transparently by ffi) or via registers
			//
			BOOL	usingStret = isUsingStret(argumentEncodings);
			void* callAddress = objc_msgSend;
			if (usingStret)	callAddress = objc_msgSend_stret;
			
			//
			// ffi data
			//
			ffi_cif		cif;
			ffi_type*	args[3];
			void*		values[3];
			char*		selector;

			selector	= (char*)NSSelectorFromString(setterName);
			args[0]		= &ffi_type_pointer;
			args[1]		= &ffi_type_pointer;
			values[0]	= (void*)&callee;
			values[1]	= (void*)&selector;

			// Get arg (skip return value, instance, selector)
			JSCocoaFFIArgument*	arg		= [argumentEncodings objectAtIndex:3];
			BOOL	converted = [arg fromJSValueRef:jsValue inContext:ctx];
			if (!converted)		return	throwException(ctx, exception, [NSString stringWithFormat:@"(in setter) Argument %c not converted", [arg typeEncoding]]), false;
			args[2]		= [arg ffi_type];
			values[2]	= [arg storage];
			
			// Setup ffi
			ffi_status prep_status	= ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 3, &ffi_type_void, args);
			//
			// Call !
			//
			if (prep_status == FFI_OK)
			{
				ffi_call(&cif, callAddress, NULL, values);
			}
			return	true;
		}
		
		if ([callee respondsToSelector:@selector(setJSValue:forJSName:)])
		{
			// Set as instance variable
//			BOOL set = [callee setJSValue:jsValue forJSName:propertyNameJS];
			JSValueRefAndContextRef value = { JSValueMakeNull(ctx), ctx };
			value.value = jsValue;

			JSValueRefAndContextRef	name = { JSValueMakeNull(ctx), ctx } ;
			name.value = JSValueMakeString(ctx, propertyNameJS);
			BOOL set = [callee setJSValue:value forJSName:name];
			if (set)	return	true;
		}
	}

	//
	// From here we return false to have Javascript set values on Javascript objects : valueOf, thisObject, structures
	//

	// Special case for autocall : allow current js object to receive a custom valueOf method that will handle autocall
	// And a thisObject property holding class for instance autocall
	if ([propertyName isEqualToString:@"valueOf"])		return	false;
	if ([propertyName isEqualToString:@"thisObject"])	return	false;
	// Allow general setting on structs
	if ([privateObject.type isEqualToString:@"struct"])	return	false;

	// Setter fails AND WARNS if propertyName can't be set
	// This happens of non-JSCocoa ObjC objects, eg NSWorkspace.sharedWorspace.someVariable = value
	return	throwException(ctx, exception, [NSString stringWithFormat:@"(in setter) object %@ does not support setting — Derive from that class to make it able to host any Javascript object ", privateObject.object]), false;
}


//
// deleteProperty
//	delete property in hash
//
static bool jsCocoaObject_deleteProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef* exception)
{
	NSString*	propertyName = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, propertyNameJS);
	[NSMakeCollectable(propertyName) autorelease];
	
	JSCocoaPrivateObject* privateObject = JSObjectGetPrivate(object);
//	NSLog(@"Deleting property %@", propertyName);

	if (![privateObject.type isEqualToString:@"@"])	return false;

	id callee	= [privateObject object];
	if (![callee respondsToSelector:@selector(setJSValue:forJSName:)])	return	false;
	JSValueRefAndContextRef	name = { JSValueMakeNull(ctx), ctx } ;
	name.value = JSValueMakeString(ctx, propertyNameJS);
	return [callee deleteJSValueForJSName:name];
}


//
// getPropertyNames
//	enumerate dictionary keys
//
static void jsCocoaObject_getPropertyNames(JSContextRef ctx, JSObjectRef object, JSPropertyNameAccumulatorRef propertyNames)
{
	// Autocall : ensure 'instance' has been called and we've got our new instance
//	[JSCocoaController ensureJSValueIsObjectAfterInstanceAutocall:object inContext:ctx];
	
	JSCocoaPrivateObject* privateObject = JSObjectGetPrivate(object);

	// If we have a dictionary, add keys from allKeys
	if ([privateObject.type isEqualToString:@"@"] && [privateObject.object isKindOfClass:[NSDictionary class]])
	{
		id dictionary	= privateObject.object;
		id keys			= [dictionary allKeys];
		
		for (id key in keys)
		{
			JSStringRef jsString = JSStringCreateWithUTF8CString([key UTF8String]);
			JSPropertyNameAccumulatorAddName(propertyNames, jsString);
			JSStringRelease(jsString);			
		}
	}
}



//
// callAsFunction 
//	done in two methods. 
//	jsCocoaObject_callAsFunction is called first and handles 
//		* C and ObjC calls : calls jsCocoaObject_callAsFunction_ffi
//		* Super call : in a derived ObjC class method, call this.Super(arguments) to call the parent method with jsCocoaObject_callAsFunction_ffi
//		* js function calls : on an ObjC class, use of pure js functions as methods
//		* toString, valueOf
//
//	jsCocoaObject_callAsFunction_ffi calls a C function or an ObjC method with provided arguments.
//

// This uses libffi to call C and ObjC.
static JSValueRef jsCocoaObject_callAsFunction_ffi(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, JSValueRef arguments[], JSValueRef* exception, NSString* superSelector, Class superSelectorClass, JSValueRef** argumentsToFree)
{
	JSCocoaPrivateObject* privateObject		= JSObjectGetPrivate(function);
	JSCocoaPrivateObject* thisPrivateObject = JSObjectGetPrivate(thisObject);

	// Return an exception if calling on NULL
	if ([thisPrivateObject object] == NULL && !privateObject.xml)	return	throwException(ctx, exception, @"jsCocoaObject_callAsFunction : call with null object"), NULL;

	// Call setup : calling ObjC or C requires
	// Function address
	void* callAddress = NULL;

	// Number of arguments of called method or function
	int callAddressArgumentCount = 0;

	// Arguments encoding
	// Holds return value encoding as first element
	NSMutableArray*	argumentEncodings = nil;

	// Calling ObjC ? If NO, we're calling C
	BOOL	callingObjC = NO;
	// Structure return (objc_msgSend_stret)
	BOOL	usingStret	= NO;


	// Get delegate
	JSCocoaController* jsc = [JSCocoaController controllerFromContext:ctx];
	id delegate = jsc.delegate;

	//
	// ObjC setup
	//
	id callee = NULL, methodName = NULL, functionName = NULL;
	if ([privateObject.type isEqualToString:@"method"] && [thisPrivateObject.type isEqualToString:@"@"])
	{
		callingObjC	= YES;
		callee		= [thisPrivateObject object];
		methodName	= superSelector ? superSelector : [NSMutableString stringWithString:privateObject.methodName];
//		NSLog(@"calling %@.%@", callee, methodName);

		//
		// Delegate canCallMethod, callMethod
		//	Called first so it gets a chance to do handle custom messages
		//
		if (delegate)
		{
			// Check if calling is allowed
			if ([delegate respondsToSelector:@selector(JSCocoa:canCallMethod:ofObject:argumentCount:arguments:inContext:exception:)])
			{
				BOOL canCall = [delegate JSCocoa:jsc canCallMethod:methodName ofObject:callee argumentCount:argumentCount arguments:arguments inContext:ctx exception:exception];
				if (!canCall)
				{
					if (!*exception)	throwException(ctx, exception, [NSString stringWithFormat:@"Delegate does not allow calling [%@ %@]", callee, methodName]);
					return	NULL;
				}
			}
			// Check if delegate handles calling
			if ([delegate respondsToSelector:@selector(JSCocoa:callMethod:ofObject:argumentCount:arguments:inContext:exception:)])
			{
				JSValueRef delegateCall = [delegate JSCocoa:jsc callMethod:methodName ofObject:callee argumentCount:argumentCount arguments:arguments inContext:ctx exception:exception];
				if (delegateCall)	return	delegateCall;
			}
		}

		// Instance call
		if ([callee class] == callee && [methodName isEqualToString:@"instance"])
		{
			if (argumentCount > 1)	return	throwException(ctx, exception, @"Invalid argument count in instance call : must be 0 or 1"), NULL;
			return	[callee instanceWithContext:ctx argumentCount:argumentCount arguments:arguments exception:exception];
		}

		// Check selector
		if (![callee respondsToSelector:NSSelectorFromString(methodName)])
		{
			//
			// Split call
			//	set( { value : '5', forKey : 'hello' } )
			//	-> setValue:forKey:
			//
			if (![callee respondsToSelector:NSSelectorFromString(methodName)])
			{
				id			splitMethodName		= privateObject.methodName;
				id class = [callee class];
				if (callee == class)
					class = objc_getMetaClass(object_getClassName(class));
				BOOL isSplitCall = [JSCocoaController trySplitCall:&splitMethodName class:class argumentCount:&argumentCount arguments:&arguments ctx:ctx];
				if (isSplitCall)		
				{
					methodName = splitMethodName;
					// trySplitCall returned new arguments that we'll need to free later on
					*argumentsToFree = arguments;
				}
			}
		}

/*
		// NSDistantObject
        if ([callee class] == [NSDistantObject class]) {
            return _jsCocoaObject_callUsingNSInvocation(ctx, callee, methodName, argumentCount, arguments);
        }
*/		
		// Get method pointer
		Method method = class_getInstanceMethod([callee class], NSSelectorFromString(methodName));
		if (!method)	method = class_getClassMethod([callee class], NSSelectorFromString(methodName));
/*
        // NSDistantObject : maybe it's a property?
        if (!method && [callee methodSignatureForSelector:NSSelectorFromString(methodName)]) {
            return _jsCocoaObject_callUsingNSInvocation(ctx, callee, methodName, argumentCount, arguments);
        }
*/
		// Bail if we can't find a suitable method
		if (!method)	
		{
			// Last chance before exception : try treating callee as string
			if ([callee isKindOfClass:[NSString class]])
			{
				id script = [NSString stringWithFormat:@"String.prototype.%@", methodName];
				JSStringRef	jsScript = JSStringCreateWithUTF8CString([script UTF8String]);
				JSValueRef result = JSEvaluateScript(ctx, jsScript, NULL, NULL, 1, NULL);
				JSStringRelease(jsScript);
				if (result && JSValueGetType(ctx, result) == kJSTypeObject)
				{
					JSStringRef string = JSStringCreateWithCFString((CFStringRef)callee);
					JSValueRef stringValue = JSValueMakeString(ctx, string);
					JSStringRelease(string);

					JSObjectRef functionObject = JSValueToObject(ctx, result, NULL);
					JSObjectRef jsThisObject = JSValueToObject(ctx, stringValue, NULL);
					JSValueRef r =	JSObjectCallAsFunction(ctx, functionObject, jsThisObject, argumentCount, arguments, NULL);
					return	r;
				}
			}
			
			return	throwException(ctx, exception, [NSString stringWithFormat:@"jsCocoaObject_callAsFunction : method %@ not found", methodName]), NULL;
		}
		
		// Extract arguments
		const char* typeEncoding = method_getTypeEncoding(method);
//		NSLog(@"method %@ encoding=%s", methodName, typeEncoding);
		argumentEncodings = [JSCocoaController parseObjCMethodEncoding:typeEncoding];
		// Function arguments is all arguments minus return value and [instance, selector] params to objc_send
		callAddressArgumentCount = [argumentEncodings count]-3;

		// Get call address
		callAddress = objc_msgSend;

		//
		// From PyObjC : when to call objc_msgSendStret, for structure return
		//		Depending on structure size & architecture, structures are returned as function first argument (done transparently by ffi) or via registers
		//
		BOOL	usingStret = isUsingStret(argumentEncodings);
		if (usingStret)	callAddress = objc_msgSend_stret;
	}

	//
	// C setup
	//
	if (!callingObjC)
	{
		if (!privateObject.xml)	return	throwException(ctx, exception, @"jsCocoaObject_callAsFunction : no xml in object = nothing to call") , NULL;
		argumentEncodings = [JSCocoaController parseCFunctionEncoding:privateObject.xml functionName:&functionName];
		// Grab symbol
		callAddress = dlsym(RTLD_DEFAULT, [functionName UTF8String]);
		if (!callAddress)	return	throwException(ctx, exception, [NSString stringWithFormat:@"Function %@ not found", functionName]), NULL;
		// Function arguments is all arguments minus return value
		callAddressArgumentCount = [argumentEncodings count]-1;

		//
		// Delegate canCallFunction
		//
		if (delegate)
		{
			// Check if calling is allowed
			if ([delegate respondsToSelector:@selector(JSCocoa:canCallFunction:argumentCount:arguments:inContext:exception:)])
			{
				BOOL canCall = [delegate JSCocoa:jsc canCallFunction:functionName argumentCount:argumentCount arguments:arguments inContext:ctx exception:exception];
				if (!canCall)
				{
					if (!*exception)	throwException(ctx, exception, [NSString stringWithFormat:@"Delegate does not allow calling function %@", functionName]);
					return	NULL;
				}
			}
		}
	}
	
	//
	// Variadic call ?
	//	If argument count doesn't match descripted argument count, 
	//	we may have a variadic call
	//
	BOOL isVariadic = NO;
	if (callAddressArgumentCount != argumentCount)	
	{
		if (methodName)		isVariadic = [[JSCocoaController controllerFromContext:ctx] isMethodVariadic:methodName class:[callee class]];
		else				isVariadic = [[JSCocoaController controllerFromContext:ctx] isFunctionVariadic:functionName];
		
		// Bail if not variadic
		if (!isVariadic)
		{
			return	throwException(ctx, exception, [NSString stringWithFormat:@"Bad argument count in %@ : expected %d, got %d", functionName ? functionName : methodName,	callAddressArgumentCount, argumentCount]), NULL;
		}
	}

	//
	// ffi data
	//
	ffi_cif		cif;
	ffi_type**	args	= NULL;
	void**		values	= NULL;
	char*		selector;
	// super call
	struct		objc_super _super;
	void*		superPointer;
	
	// Total number of arguments to ffi_call
	int	effectiveArgumentCount = argumentCount + (callingObjC ? 2 : 0);
	if (effectiveArgumentCount > 0)
	{
		args = malloc(sizeof(ffi_type*)*effectiveArgumentCount);
		values = malloc(sizeof(void*)*effectiveArgumentCount);

		// If calling ObjC, setup instance and selector
		int		i, idx = 0;
		if (callingObjC)
		{
			selector	= (char*)NSSelectorFromString(methodName);
			args[0]		= &ffi_type_pointer;
			args[1]		= &ffi_type_pointer;
			values[0]	= (void*)&callee;
			values[1]	= (void*)&selector;
			idx = 2;
			
			// Super handling
			if (superSelector)
			{
				if (superSelectorClass == nil)	return	throwException(ctx, exception, [NSString stringWithFormat:@"Null superclass in %@", callee]), NULL;
				callAddress = objc_msgSendSuper;
				if (usingStret)	callAddress = objc_msgSendSuper_stret;
				_super.receiver = callee;
#if TARGET_IPHONE_SIMULATOR || !TARGET_OS_IPHONE
				_super.class	= superSelectorClass;
#else			
				_super.super_class	= superSelectorClass;
#endif			
				superPointer	= &_super;
				values[0]		= &superPointer;
//				NSLog(@"superClass=%@ (old=%@) (%@) function=%x", superSelectorClass, [callee superclass], [callee class], function);
			}
		}
		
		// Setup arguments, unboxing or converting data
		for (i=0; i<argumentCount; i++, idx++)
		{
			// All variadic arguments are treated as ObjC objects (@)
			JSCocoaFFIArgument*	arg;
			if (isVariadic && i >= callAddressArgumentCount)
			{
				arg = [[JSCocoaFFIArgument alloc] init];
				[arg setTypeEncoding:'@'];
				[arg autorelease];
			}
			else
				arg		= [argumentEncodings objectAtIndex:idx+1];


			// Convert argument
			JSValueRef			jsValue	= arguments[i];
			BOOL	shouldConvert = YES;
			// Check type o modifiers
			if ([arg typeEncoding] == '^')
			{
				// If holding a JSCocoaOutArgument, allocate custom storage
				if (JSValueGetType(ctx, jsValue) == kJSTypeObject)
				{
					id unboxed = nil;
					[JSCocoaFFIArgument unboxJSValueRef:jsValue toObject:&unboxed inContext:ctx];
					if (unboxed && [unboxed isKindOfClass:[JSCocoaOutArgument class]])
					{
						if (![(JSCocoaOutArgument*)unboxed mateWithJSCocoaFFIArgument:arg])	return	throwException(ctx, exception, [NSString stringWithFormat:@"Pointer argument %@ not handled", [arg pointerTypeEncoding]]), NULL;
						shouldConvert = NO;
					}
					if (unboxed && [unboxed isKindOfClass:[JSCocoaMemoryBuffer class]])
					{
						JSCocoaMemoryBuffer* buffer = unboxed;
						[arg setTypeEncoding:[arg typeEncoding] withCustomStorage:[buffer pointerForIndex:0]];
						shouldConvert = NO;
					}
				}
				else
				// Allocate default storage
					[arg allocateStorage];
			}

			args[idx]		= [arg ffi_type];
			if (shouldConvert)
			{
				BOOL	converted = [arg fromJSValueRef:jsValue inContext:ctx];
				if (!converted)		return	throwException(ctx, exception, [NSString stringWithFormat:@"Argument %c not converted", [arg typeEncoding]]), NULL;
			}
			values[idx]		= [arg storage];
		}
	}

	// Get return value holder
	id returnValue = [argumentEncodings objectAtIndex:0];

	// Setup ffi
	ffi_status prep_status	= ffi_prep_cif(&cif, FFI_DEFAULT_ABI, effectiveArgumentCount, [returnValue ffi_type], args);
	//
	// Call !
	//
	if (prep_status == FFI_OK)
	{
		void* storage = [returnValue storage];
		if ([returnValue ffi_type] == &ffi_type_void)	storage = NULL;
//		log_ffi_call(&cif, values, callAddress);
		ffi_call(&cif, callAddress, storage, values);
	}
	
	if (effectiveArgumentCount > 0)	
	{
		free(args);
		free(values);
	}
	if (prep_status != FFI_OK)	return	throwException(ctx, exception, @"ffi_prep_cif failed"), NULL;
	
	// Return now if our function returns void
	// Return null as a JSValueRef to avoid crashing
	if ([returnValue ffi_type] == &ffi_type_void)	return	JSValueMakeNull(ctx);
	
	// Else, convert return value
	JSValueRef	jsReturnValue = NULL;
	BOOL converted = [returnValue toJSValueRef:&jsReturnValue inContext:ctx];
	if (!converted)	return	throwException(ctx, exception, [NSString stringWithFormat:@"Return value not converted in %@", methodName?methodName:functionName]), NULL;
	
	return	jsReturnValue;
}

//
// This method handles
//		* C and ObjC calls
//		* Super call : retrieves the method name to call, thereby giving new arguments to jsCocoaObject_callAsFunction_ffi
//		* js function calls : on an ObjC class, use of pure js functions as methods
//		* toString, valueOf
//
static JSValueRef jsCocoaObject_callAsFunction(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception)
{
	JSCocoaPrivateObject* privateObject		= JSObjectGetPrivate(function);
	JSValueRef*	superArguments	= NULL;
	id	superSelector			= NULL;
	id	superSelectorClass		= NULL;

	// Pure JS functions for derived ObjC classes
	if ([privateObject jsValueRef] && [privateObject.type isEqualToString:@"jsFunction"])
	{
		JSObjectRef jsFunction = JSValueToObject(ctx, [privateObject jsValueRef], NULL);
		JSValueRef ret = JSObjectCallAsFunction(ctx, jsFunction, thisObject, argumentCount, arguments, exception);
		return	ret;
	}
	// Javascript custom methods
	if ([privateObject.methodName isEqualToString:@"toString"] || [privateObject.methodName isEqualToString:@"valueOf"])
	{
		JSValueRef jsValue = valueOfCallback(ctx, function, thisObject, 0, NULL, NULL);
		if ([privateObject.methodName isEqualToString:@"toString"])	
		{
			JSStringRef str = JSValueToStringCopy(ctx, jsValue, NULL);
			JSValueRef ret = JSValueMakeString(ctx, str);
			JSStringRelease(str);
			return ret;
		}
		return	jsValue;
	}
	
	// Super handling : get method name and move js arguments to C array
	if ([privateObject.methodName isEqualToString:@"Super"])
	{
		if (argumentCount != 1)	return	throwException(ctx, exception, @"Super wants one argument array"), NULL;

		// Get argument object
		JSObjectRef argumentObject = JSValueToObject(ctx, arguments[0], NULL);
		
		// Get argument count
		JSStringRef	jsLengthName = JSStringCreateWithUTF8CString("length");
		JSValueRef	jsLength = JSObjectGetProperty(ctx, argumentObject, jsLengthName, NULL);
		JSStringRelease(jsLengthName);
		if (JSValueGetType(ctx, jsLength) != kJSTypeNumber)	return	throwException(ctx, exception, @"Super has no arguments"), NULL;
		
		int i, superArgumentCount = (int)JSValueToNumber(ctx, jsLength, NULL);
		if (superArgumentCount)
		{
			superArguments = malloc(sizeof(JSValueRef)*superArgumentCount);
			for (i=0; i<superArgumentCount; i++)
				superArguments[i] = JSObjectGetPropertyAtIndex(ctx, argumentObject, i, NULL);
		}
		
		argumentCount = superArgumentCount;
		
		// Get method name and associated class (need class for obj_msgSendSuper)
		JSStringRef	jsCalleeName = JSStringCreateWithUTF8CString("callee");
		JSValueRef	jsCalleeValue = JSObjectGetProperty(ctx, argumentObject, jsCalleeName, NULL);
		JSStringRelease(jsCalleeName);
		JSObjectRef jsCallee = JSValueToObject(ctx, jsCalleeValue, NULL);
		superSelector = [[JSCocoaController controllerFromContext:ctx] selectorForJSFunction:jsCallee];
		if (!superSelector)	return	throwException(ctx, exception, @"Super couldn't find parent method"), NULL;
		superSelectorClass = [[[JSCocoaController controllerFromContext:ctx] classForJSFunction:jsCallee] superclass];
	}

	JSValueRef* functionArguments	= superArguments ? superArguments : (JSValueRef*)arguments;
	JSValueRef*	argumentsToFree		= NULL;
	JSValueRef jsReturnValue = jsCocoaObject_callAsFunction_ffi(ctx, function, thisObject, argumentCount, functionArguments, exception, superSelector, superSelectorClass, &argumentsToFree);
	
	if (superArguments)		free(superArguments);
	if (argumentsToFree)	free(argumentsToFree);
	
	return	jsReturnValue;
}
/*
//
// NSDistantObject call, courtesy of Gus Mueller
//
static JSValueRef _jsCocoaObject_callUsingNSInvocation(JSContextRef ctx, id callee, NSString *methodName, size_t argumentCount, JSValueRef arguments[]) {
    
    SEL selector = NSSelectorFromString(methodName);
    NSMethodSignature *signature = [callee methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setSelector:selector];
    
    NSUInteger argIndex = 0;
    while (argIndex < argumentCount) {
        
        id arg = 0x00;
        
        [JSCocoaFFIArgument unboxJSValueRef:arguments[argIndex] toObject:&arg inContext:ctx];
        
        [invocation setArgument:&arg atIndex:argIndex + 2];
        
        argIndex++;
    }
    
    
    [invocation invokeWithTarget:callee];
    
    id result = 0x00;
    
    const char *type = [signature methodReturnType];
    
    if (strcmp(type, @encode(id)) == 0) {
        [invocation getReturnValue:&result];
    }
    
    if (!result) {
        return JSValueMakeNull(ctx);
    }
    
    JSValueRef	jsReturnValue = NULL;
    
    [JSCocoaFFIArgument boxObject:result toJSValueRef:&jsReturnValue inContext:ctx];
    
    return	jsReturnValue;
}
*/


//
// Creating new structures with Javascript's new operator
//
//	// Zero argument call : fill with undefined
//	var p = new NSPoint					returns { origin : { x : undefined, y : undefined }, size : { width : undefined, height : undefined } }
//
//	// Initial values argument call : fills structure with arguments[] contents — THROWS exception if arguments.length != structure.elementCount 
//	var p = new NSPoint(1, 2, 3, 4)		returns { origin : { x : 1, y : 2 }, size : { width : 3, height : 4 } }
//
static JSObjectRef jsCocoaObject_callAsConstructor(JSContextRef ctx, JSObjectRef constructor, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception)
{
	JSCocoaPrivateObject* privateObject = JSObjectGetPrivate(constructor);
	if (!privateObject)		return throwException(ctx, exception, @"Calling set on a non mutable dictionary"), NULL;
	if (![[privateObject type] isEqualToString:@"struct"] || !privateObject.xml)		return throwException(ctx, exception, @"Calling constructor on a non struct"), NULL;

	// Get structure type
	id xmlDocument = [[NSXMLDocument alloc] initWithXMLString:privateObject.xml options:0 error:nil];
	id rootElement = [xmlDocument rootElement];
	id structureType = [[rootElement attributeForName:@"type"] stringValue];
	[xmlDocument release];
	id fullStructureType = [JSCocoaFFIArgument structureFullTypeEncodingFromStructureTypeEncoding:structureType];
	if (!fullStructureType)	return throwException(ctx, exception, @"Calling constructor on a non struct"), NULL;

//	NSLog(@"Call as constructor structure %@ with %d arguments", fullStructureType, argumentCount);

	// Create Javascript object out of structure type
	JSValueRef	convertedStruct = NULL;
	int			convertedValueCount = 0;
	[JSCocoaFFIArgument structureToJSValueRef:&convertedStruct inContext:ctx fromCString:(char*)[fullStructureType UTF8String] fromStorage:nil initialValues:(JSValueRef*)arguments initialValueCount:argumentCount convertedValueCount:&convertedValueCount];

	// If constructor is called with arguments, make sure they are the correct amount to fill all structure slots
	if (argumentCount)
	{
		if (convertedValueCount != argumentCount)
		{
			return throwException(ctx, exception, [NSString stringWithFormat:@"Bad argument count when calling constructor on a struct : expected %d, got %d", convertedValueCount, argumentCount]), NULL;
		}
	}
	
	if (!convertedStruct)	return throwException(ctx, exception, @"Cound not instance structure"), NULL;
	return	JSValueToObject(ctx, convertedStruct, NULL);
}



//
// convertToType
//
static JSValueRef jsCocoaObject_convertToType(JSContextRef ctx, JSObjectRef object, JSType type, JSValueRef* exception)
{
	// Only invoked when converting to strings and numbers.
	// Would have been useful to be called on BOOLs too, to avoid false positives of ('varname' in object) when varname may start a split call.
	
	// Used on string conversions, eg jsHash[objcNSString] to convert objcNSString to a js string
	return	valueOfCallback(ctx, NULL, object, 0, NULL, NULL);
//	return	NULL;
}





#pragma mark Helpers

id	NSStringFromJSValue(JSValueRef value, JSContextRef ctx)
{
	JSStringRef resultStringJS = JSValueToStringCopy(ctx, value, NULL);
	NSString* resultString = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, resultStringJS);
	JSStringRelease(resultStringJS);
	return	[NSMakeCollectable(resultString) autorelease];
}

static void throwException(JSContextRef ctx, JSValueRef* exception, NSString* reason)
{
	// Don't speak and log here as the exception may be caught
	if (logAllExceptions)
	{
		NSLog(@"JSCocoa exception : %@", reason);
		if (isSpeaking)	system([[NSString stringWithFormat:@"say \"%@\" &", reason] UTF8String]);
	}

	// Gather call stack
	JSStringRef scriptJS = JSStringCreateWithUTF8CString("return dumpCallStack()");
	JSObjectRef fn = JSObjectMakeFunction(ctx, NULL, 0, NULL, scriptJS, NULL, 0, NULL);
	JSValueRef result = JSObjectCallAsFunction(ctx, fn, NULL, 0, NULL, NULL);
	JSStringRelease(scriptJS);

	// Convert call stack to string
	JSStringRef resultStringJS = JSValueToStringCopy(ctx, result, NULL);
	NSString* callStack = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, resultStringJS);
	JSStringRelease(resultStringJS);
	[NSMakeCollectable(callStack) autorelease];

	// Append call stack to exception
	if ([callStack length])
		reason = [NSString stringWithFormat:@"%@\n%@", reason, callStack];
	JSStringRef jsName = JSStringCreateWithUTF8CString([reason UTF8String]);
	JSValueRef jsString = JSValueMakeString(ctx, jsName);
	JSStringRelease(jsName);
	
//	*exception	= jsString;
	// Convert to object to allow JavascriptCore to add line and sourceURL
	*exception	= JSValueToObject(ctx, jsString, NULL);
}
/*
// Can't use in GC as data does not live until the end of the current run loop cycle
void* malloc_autorelease(size_t size)
{
	void*	p = malloc(size);
	[NSData dataWithBytesNoCopy:p length:size freeWhenDone:YES];
	return	p;
}
*/

//
// JSLocalizedString
//
id	JSLocalizedString(id stringName, id firstArg, ...)
{
	// Convert args to array
	id arg, arguments = [NSMutableArray array];
	[arguments addObject:stringName];
	if (firstArg)	[arguments addObject:firstArg];

	if (firstArg)
	{
		va_list	args;
		va_start(args, firstArg);
		while (arg = va_arg(args, id))	[arguments addObject:arg];
		va_end(args);
	}
	
	// Get global object
	id				jsc			= [JSCocoaController sharedController];
	JSContextRef	ctx			= [jsc ctx];
	JSObjectRef		globalObject= JSContextGetGlobalObject(ctx);
	JSValueRef		exception	= NULL;
	
	// Get function as property of global object
	JSStringRef jsFunctionName = JSStringCreateWithUTF8CString([@"localizedString" UTF8String]);
	JSValueRef jsFunctionValue = JSObjectGetProperty(ctx, globalObject, jsFunctionName, &exception);
	JSStringRelease(jsFunctionName);
	if (exception)				return	NSLog(@"localizedString failed"), NULL;
	
	JSObjectRef	jsFunction = JSValueToObject(ctx, jsFunctionValue, NULL);
	// Return if function is not of function type
	if (!jsFunction)			return	NSLog(@"localizedString is not a function"), NULL;

	// Call !
	JSValueRef jsRes = [jsc callJSFunction:jsFunction withArguments:arguments];
	id res = [jsc unboxJSValueRef:jsRes];

	return	res;
}



//
// JSCocoa shorthand
//
@implementation JSCocoa
@end


//
// Boxed object cache
//
@implementation BoxedJSObject

- (void)setJSObject:(JSObjectRef)o
{
	jsObject = o;
}
- (JSObjectRef)jsObject
{
	return	jsObject;
}

- (id)description
{
	id boxedObject = [(JSCocoaPrivateObject*)JSObjectGetPrivate(jsObject) object];
	return [NSString stringWithFormat:@"<%@: %x holding %@ %@: %x (retainCount=%d)>",
				[self class], 
				self, 
				((id)self == (id)[self class]) ? @"Class" : @"",
				[boxedObject class],
				boxedObject,
				[boxedObject retainCount]];
}

@end
