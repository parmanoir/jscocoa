//
//  JSCocoa.m
//  JSCocoa
//
//  Created by Patrick Geiller on 09/07/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//


#import "JSCocoaController.h"

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
#ifdef JSCocoa_iPhone
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

@implementation JSCocoaController
@synthesize useAutoCall, isSpeaking, logAllExceptions;


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
			NSLog(@"JSCocoa : allocating shared instance %x", JSCocoaSingleton);
			[JSCocoaSingleton init];
		}
	}
	return	JSCocoaSingleton;
}
+ (BOOL)hasSharedController
{
	return	!!JSCocoaSingleton;
}

//
// Init
//
- (id)init
{
	NSLog(@"JSCocoa : %x spawning", self);
	id o	= [super init];

	closureHash			= [[NSMutableDictionary alloc] init];
	jsFunctionSelectors	= [[NSMutableDictionary alloc] init];
	jsFunctionClasses	= [[NSMutableDictionary alloc] init];
	jsFunctionHash		= [[NSMutableDictionary alloc] init];
	instanceStats		= [[NSMutableDictionary alloc] init];
	splitCallCache		= [[NSMutableDictionary alloc] init];
	jsClassParents		= [[NSMutableDictionary alloc] init];

	useAutoCall			= YES;
	isSpeaking			= YES;
//	isSpeaking			= NO;
	logAllExceptions	= NO;

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
	
	// Create callback used for autocall, set as property on JavascriptCore's [CallbackObject]
	callbackObjectValueOfCallback = JSObjectMakeFunctionWithCallback(ctx, NULL, valueOfCallback);
	// And protect it from GC
	JSValueProtect(ctx, callbackObjectValueOfCallback);
	JSStringRef	jsName = JSStringCreateWithUTF8CString("__valueOfCallback__");
	JSObjectSetProperty(ctx, JSContextGetGlobalObject(ctx), jsName, callbackObjectValueOfCallback, kJSPropertyAttributeReadOnly+kJSPropertyAttributeDontEnum+kJSPropertyAttributeDontDelete, NULL);
	JSStringRelease(jsName);

	// Create a reference to ourselves
	JSObjectRef jsc = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
	JSCocoaPrivateObject* private = JSObjectGetPrivate(jsc);
	private.type = @"@";
	// If we've overloaded retain, we'll be calling ourselves until the stack dies
	[private setObjectNoRetain:self];
	jsName = JSStringCreateWithUTF8CString("__jsc__");
	JSObjectSetProperty(ctx, JSContextGetGlobalObject(ctx), jsName, jsc, kJSPropertyAttributeReadOnly+kJSPropertyAttributeDontEnum+kJSPropertyAttributeDontDelete, NULL);
	JSStringRelease(jsName);
	

#ifndef JSCocoa_iPhone
	[self loadFrameworkWithName:@"AppKit"];
	[self loadFrameworkWithName:@"CoreFoundation"];
	[self loadFrameworkWithName:@"Foundation"];
	[self loadFrameworkWithName:@"CoreGraphics" inPath:@"/System/Library/Frameworks/ApplicationServices.framework/Frameworks"];
#endif	

	// Load class kit
	[self evalJSFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"class" ofType:@"js"]];
	
	return	o;
}

//
// Dealloc
//
- (void)cleanUp
{
	NSLog(@"JSCocoa : %x dying", self);
	JSValueUnprotect(ctx, callbackObjectValueOfCallback);
	
	[self unlinkAllReferences];
	JSGarbageCollect(NULL);
	JSGlobalContextRelease(ctx);

	[instanceStats release];
	[jsFunctionHash release];
	[jsFunctionClasses release];
	[jsFunctionSelectors release];
	[closureHash release];
	[splitCallCache release];
	[jsClassParents release];
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

# pragma mark Unclassed methods
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
	if ([[self sharedController] isSpeaking])	system([[NSString stringWithFormat:@"say %@ &", string] UTF8String]);
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


- (JSGlobalContextRef)ctx
{
	return	ctx;
}

- (id)instanceStats
{
	return	instanceStats;
}


- (JSObjectRef)callbackObjectValueOfCallback
{
	return	callbackObjectValueOfCallback;
}

//
// Set a valueOf callback on a jsObject
//
//- (void)setValueOfCallBackOnJSObject:(JSObjectRef)jsObject
+ (void)setValueOfCallBackOnJSObject:(JSObjectRef)jsObject inContext:(JSContextRef)ctx
{
	// Get valueOf callback
	JSStringRef jsName = JSStringCreateWithUTF8CString("__valueOfCallback__");
	JSValueRef valueOfCallback = JSObjectGetProperty(ctx, JSContextGetGlobalObject(ctx), jsName, NULL);
	JSStringRelease(jsName);					
	// Add it to object
	jsName = JSStringCreateWithUTF8CString("valueOf");
//	JSObjectSetProperty(ctx, jsObject, jsName, [self callbackObjectValueOfCallback], JSCocoaInternalAttribute, NULL);
	JSObjectSetProperty(ctx, jsObject, jsName, valueOfCallback, JSCocoaInternalAttribute, NULL);
	JSStringRelease(jsName);					
}

// On auto calling 'instance' (eg NSString.instance), call is not done on property get (unlike NSWorkspace.sharedWorkspace)
// Instancing can't happen on get as instance may have parameters. 
// Instancing will therefore be delayed and must happen
//	* in fromJSValueRef
//	* in property get (NSString.instance.count, getting 'count')
//	* in valueOf (handled automatically as JavascriptCore will request 'valueOf' through property get)
+ (void)ensureJSValueIsObjectAfterInstanceAutocall:(JSValueRef)jsValue inContext:(JSContextRef)ctx;
{
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

//	NSLog(@"Instance autocall on class %@", [privateObject object]);

	// Create new instance and patch it into object
	id newInstance = [[[privateObject object] alloc] init];
	JSCocoaPrivateObject* instanceObject = JSObjectGetPrivate(jsObject);
	instanceObject.type = @"@";
	[instanceObject setObject:newInstance];
	// Make JS object sole owner
	[newInstance release];
}

- (const char*)typeEncodingOfMethod:(NSString*)methodName class:(NSString*)className
{
	id class = objc_getClass([className UTF8String]);
	if (!class)	return	nil;
	
	Method m = class_getClassMethod(class, NSSelectorFromString(methodName));
	if (!m)		m = class_getInstanceMethod(class, NSSelectorFromString(methodName));
	if (!m)		return	nil;
	
	return	method_getTypeEncoding(m);	
}


- (id)parentObjCClassOfClassName:(NSString*)className
{
	return	[jsClassParents objectForKey:className];
}

#pragma mark Common encoding parsing
// Use method_copyArgumentType ?
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

			id encoding = [[NSString alloc] initWithBytes:argsParser length:count encoding:NSASCIIStringEncoding];
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
			// ##TOFIX : copy pointer type (^i, ^{NSRect}) to the argumentEncoding
			char type = *argsParser;
			if (*argsParser == '^')
				while (*argsParser && !(*argsParser >= '0' && *argsParser <= '9'))	argsParser++;

			id argumentEncoding = [[JSCocoaFFIArgument alloc] init];
			// Set return value
			if ([argumentEncodings count] == 0)	[argumentEncoding setIsReturnValue:YES];
			[argumentEncoding setTypeEncoding:type];
			[argumentEncodings addObject:argumentEncoding];
			[argumentEncoding release];
		}
		if (!*argsParser)	break;
	}
	return	argumentEncodings;
}

+ (NSMutableArray*)parseCFunctionEncoding:(NSString*)xml functionName:(NSString**)functionNamePlaceHolder
{
	id argumentEncodings = [NSMutableArray array];
	id xmlDocument = [[NSXMLDocument alloc] initWithXMLString:xml options:0 error:nil];
	[xmlDocument autorelease];

	id rootElement = [xmlDocument rootElement];
	*functionNamePlaceHolder = [[rootElement attributeForName:@"name"] stringValue];
	
	// Parse children and return alue
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
			if ([argumentEncodings count] == 0)	[argumentEncoding setIsReturnValue:YES];
			if (typeEncodingChar == '{')		[argumentEncoding setStructureTypeEncoding:typeEncoding];
			else								[argumentEncoding setTypeEncoding:typeEncodingChar];

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

- (Class)createClass:(char*)className parentClass:(char*)parentClass
{
	Class class = objc_getClass(className);
	if (class)	return class;
	// Return now if parent class does not exist
	if (!objc_getClass(parentClass))	return	nil;
	// Each new class gets room for a js hash storing data and some get / set methods
	class = objc_allocateClassPair(objc_getClass(parentClass), className, 0);
	// Only add on classes that don't have the js data
	BOOL hasHash = !!class_getInstanceVariable(objc_getClass(parentClass), "__jsHash");
	if (!hasHash)	class_addIvar(class, "__jsHash", sizeof(void*), log2(sizeof(void*)), "^");
	// Finish creating class
	objc_registerClassPair(class);

	// After creating class, add js methods : custom dealloc, get / set
	id JSCocoaMethodHolderClass = objc_getClass("JSCocoaMethodHolder");
	Method deallocJS = class_getInstanceMethod(JSCocoaMethodHolderClass, @selector(deallocAndCleanupJS));
	IMP deallocJSImp = method_getImplementation(deallocJS);
	if (!hasHash)
	{
		// Add dealloc
		class_addMethod(class, @selector(dealloc), deallocJSImp, method_getTypeEncoding(deallocJS));
		
		// Add js hash get / set /delete
		Method m = class_getInstanceMethod(JSCocoaMethodHolderClass, @selector(setJSValue:forJSName:));
		class_addMethod(class, @selector(setJSValue:forJSName:), method_getImplementation(m), method_getTypeEncoding(m));

		m = class_getInstanceMethod(JSCocoaMethodHolderClass, @selector(JSValueForJSName:));
		class_addMethod(class, @selector(JSValueForJSName:), method_getImplementation(m), method_getTypeEncoding(m));

		m = class_getInstanceMethod(JSCocoaMethodHolderClass, @selector(deleteJSValueForJSName:));
		class_addMethod(class, @selector(deleteJSValueForJSName:), method_getImplementation(m), method_getTypeEncoding(m));		

		// Alloc debug
		m = class_getClassMethod(JSCocoaMethodHolderClass, @selector(allocWithZone:));
		class_addMethod(objc_getMetaClass(className), @selector(allocWithZone:), method_getImplementation(m), method_getTypeEncoding(m));	

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

- (BOOL)overloadInstanceMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext
{
	JSObjectRef jsObject = JSValueToObject(valueAndContext.ctx, valueAndContext.value, NULL);
	if (!jsObject)	return	NSLog(@"overloadInstanceMethod : function is not an object"), NO;
	
	SEL selector = NSSelectorFromString(methodName);
	Method m = class_getInstanceMethod(class, selector);
	if (!m)			return NSLog(@"overloadInstanceMethod : can't overload a method that does not exist - %@.%@", class, methodName), NO;
//	NSLog(@"overloading %@ (%s)", methodName, encoding);
	return	[self addInstanceMethod:methodName class:class jsFunction:valueAndContext encoding:(char*)method_getTypeEncoding(m)];
}

- (BOOL)overloadClassMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext
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
/*
void blah(id a, SEL b)
{
}
*/
- (BOOL)addMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext encoding:(char*)encoding
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
	
	
	id privateObject = [[JSCocoaPrivateObject alloc] init];
	[privateObject setJSValueRef:valueAndContext.value ctx:valueAndContext.ctx];

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


- (BOOL)addInstanceMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext encoding:(char*)encoding
{
	return [self addMethod:methodName class:class jsFunction:valueAndContext encoding:encoding];
}
- (BOOL)addClassMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext encoding:(char*)encoding
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
- (BOOL)trySplitCall:(id*)_methodName class:(Class)class argumentCount:(size_t*)_argumentCount arguments:(JSValueRef**)_arguments ctx:(JSContextRef)c
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
		actualArguments[i] = JSObjectGetProperty(ctx, o, jsName, NULL);
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
- (BOOL)isMaybeSplitCall:(NSString*)_start forClass:(id)class
{
//	id key = [NSString stringWithFormat:@"%@ %@", [obj class], str];
	int i;

	id start = [_start lowercaseString];
	// Search through every class level
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
			if ([name hasPrefix:start])
			{
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
//
- (NSString*)formatJSException:(JSValueRef)exception
{
	JSStringRef resultStringJS = JSValueToStringCopy(ctx, exception, NULL);
	NSString* b = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, resultStringJS);
	JSStringRelease(resultStringJS);
	[NSMakeCollectable(b) autorelease];

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


#pragma mark Script evaluation

//
// Evaluate a file
// 
- (BOOL)evalJSFile:(NSString*)path toJSValueRef:(JSValueRef*)returnValue
{
	NSError*	error;
	id script = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
	// Skip .DS_Store and directories
	if (script == nil)	return	NSLog(@"evalJSFile could not open %@ (%@) — Check file encoding and file build phase (Should be in \"Copy Bundle Resources\")", path, error), NO;
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
		NSLog(@"JSException in %@ : %@", path, [self formatJSException:exception]);
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
- (JSValueRefAndContextRef)evalJSString:(NSString*)script
{
	JSValueRefAndContextRef	v = { JSValueMakeNull(ctx), NULL };
	if (!script)	return	v;
    JSStringRef scriptJS = JSStringCreateWithCFString((CFStringRef)script);
	JSValueRef exception = NULL;
    JSValueRef result = JSEvaluateScript(ctx, scriptJS, NULL, scriptJS, 1, &exception);
    JSStringRelease(scriptJS);

	v.ctx = ctx;
	v.value = JSValueMakeNull(ctx);
    if (exception) 
	{
		NSLog(@"JSException in %@ : %@", @"js string", [self formatJSException:exception]);
		return	v;
    }
	
	v.ctx = ctx;
	v.value = result;
	return	v;
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
		NSLog(@"JSException in callJSFunction : %@", [self formatJSException:exception]);
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
	if (exception)				return	NSLog(@"%@", [self formatJSException:exception]), NULL;
	
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
	if (exception)				return	NSLog(@"%@", [self formatJSException:exception]), NO;
	
	return	!!JSValueToObject(ctx, jsFunctionValue, NULL);	
}


//
// Add/Remove an ObjC object variable to the global context
//
- (BOOL)setObject:(id)object withName:(id)name
{
	JSObjectRef o = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
	JSCocoaPrivateObject* private = JSObjectGetPrivate(o);
	private.type = @"@";
	[private setObject:object];

	// Set
	JSValueRef	exception = NULL;
	JSStringRef	jsName = JSStringCreateWithUTF8CString([name UTF8String]);
	JSObjectSetProperty(ctx, JSContextGetGlobalObject(ctx), jsName, o, kJSPropertyAttributeNone, &exception);
	JSStringRelease(jsName);

    if (exception)	return	NSLog(@"JSException in setObject:withName : %@", [self formatJSException:exception]), NO;
	return	YES;
}

- (BOOL)removeObjectWithName:(id)name
{
	JSValueRef	exception = NULL;
	// Delete
	JSStringRef	jsName = JSStringCreateWithUTF8CString([name UTF8String]);
	JSObjectDeleteProperty(ctx, JSContextGetGlobalObject(ctx), jsName, &exception);
	JSStringRelease(jsName);

    if (exception)	return	NSLog(@"JSException in setObject:withName : %@", [self formatJSException:exception]), NO;
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
		[JSCocoaController garbageCollect];
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
+ (void)garbageCollect
{
	JSGarbageCollect(NULL);
}

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
/*
//
// Release a boxed objc instance now
//
- (BOOL)releaseBoxedObject:(JSValueRefAndContextRef)valueAndContext
{
	JSObjectRef jsObject = JSValueToObject(valueAndContext.ctx, valueAndContext.value, NULL);
	if (!jsObject)	return	NO;
	JSCocoaPrivateObject* private = JSObjectGetPrivate(jsObject);
	id o = private.object;
NSLog(@"releaseBoxedObject:%d->%d", [o retainCount], [o retainCount]-1);
	[o release];
	private.type = nil;	
	[private setObject:nil];

	return	YES;
}
*/

//
// ##HACK Manual cleanup for retainCount as Instruments' leak template crashes if using a JS method 
//	(retainCount gets called during GC, asserting in JavascriptCore)
//
- (NSUInteger)blankRetainCount
{
//	return	[super retainCount];
	id parentClass = [self parentObjCClassOfClassName:[NSString stringWithUTF8String:class_getName([self class])]];
	struct objc_super superData = { self, parentClass };
	return	(NSUInteger)objc_msgSendSuper(&superData, @selector(retainCount));
}
- (void)cleanRetainCount:(id)class
{
	Method m = class_getInstanceMethod(class, @selector(retainCount));
	Method m2 = class_getInstanceMethod([self class], @selector(blankRetainCount));
	method_setImplementation(m, method_getImplementation(m2));
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

	id stats = [[JSCocoaController sharedController] instanceStats];
	id key = [NSMutableString stringWithFormat:@"%@", [o class]];
	
	id existingCount = [stats objectForKey:key];
	int count = 0;
	if (existingCount)	count = [existingCount intValue];
	
	count++;
	[stats setObject:[NSNumber numberWithInt:count] forKey:key];
}
+ (void)downInstanceCount:(id)o
{
//	NSLog(@"DOWN %@ %x", o, o);
	liveInstanceCount--;

	id stats = [[JSCocoaController sharedController] instanceStats];
	id key = [NSMutableString stringWithFormat:@"%@", [o class]];
	
	id existingCount = [stats objectForKey:key];
	if (!existingCount)
	{
		NSLog(@"downInstanceCount on %@ without any up", o);
		return;
	}
	int count = [existingCount intValue];
	count--;
	
	if (count)	[stats setObject:[NSNumber numberWithInt:count] forKey:key];
	else		[stats removeObjectForKey:key];
}
+ (int)liveInstanceCount:(Class)c
{
	id key = [NSMutableString stringWithFormat:@"%@", c];
	
	id stats = [[JSCocoaController sharedController] instanceStats];
	id existingCount = [stats objectForKey:key];
	if (!existingCount)	return	0;
	return	[existingCount intValue];
}
+ (id)liveInstanceHash
{
	return	[[JSCocoaController sharedController] instanceStats];
}


+ (void)logInstanceStats
{
	id stats = [[JSCocoaController sharedController] instanceStats];
	id allKeys = [stats allKeys];
	NSLog(@"====instanceStats : %d classes spawned %d live instances (%d since launch, %d dead)====", [allKeys count], liveInstanceCount, fullInstanceCount, fullInstanceCount-liveInstanceCount);
	for (id key in allKeys)		NSLog(@"====%@=%d", key, [[stats objectForKey:key] intValue]);
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
		JSContextRef c = [[JSCocoaController sharedController] ctx];
        JSStringRef name = JSValueToStringCopy(c, nameAndContext.value, NULL);
	
		JSObjectRef hash = NULL;
		object_getInstanceVariable(self, "__jsHash", (void**)&hash);
		if (!hash)
		{
			hash = JSObjectMake(c, hashObjectClass, NULL);
			object_setInstanceVariable(self, "__jsHash", (void*)hash);
			JSValueProtect(c, hash);
			[JSCocoaController upJSValueProtectCount];
			[JSCocoaController upJSCocoaHashCount];
		}
	
//		NSLog(@"SET JS VALUE %x %@", valueAndContext.value, [JSStringCopyCFString(kCFAllocatorDefault, name) autorelease]);
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
		JSContextRef c = [[JSCocoaController sharedController] ctx];
        JSStringRef name = JSValueToStringCopy(c, nameAndContext.value, NULL);
	
		JSObjectRef hash = NULL;
		object_getInstanceVariable(self, "__jsHash", (void**)&hash);
		if (!hash)	return	valueAndContext;
		if (!JSObjectHasProperty(c, hash, name))	return	valueAndContext;

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
		JSContextRef c = [[JSCocoaController sharedController] ctx];
        JSStringRef name = JSValueToStringCopy(c, nameAndContext.value, NULL);
	
		JSObjectRef hash = NULL;
		object_getInstanceVariable(self, "__jsHash", (void**)&hash);
		if (!hash)										return	JSStringRelease(name), NO;
		if (!JSObjectHasProperty(c, hash, name))		return	JSStringRelease(name), NO;
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
	id parentClass = [[JSCocoaController sharedController] parentObjCClassOfClassName:[NSString stringWithUTF8String:class_getName(self)]];
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
		JSValueUnprotect([[JSCocoaController sharedController] ctx], hash);
		[JSCocoaController downJSCocoaHashCount];
	}
	[JSCocoaController downInstanceCount:self];

	// Dynamic super call
	id parentClass = [[JSCocoaController sharedController] parentObjCClassOfClassName:[NSString stringWithUTF8String:class_getName([self class])]];
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
		JSValueUnprotect([[JSCocoaController sharedController] ctx], hash);
		[JSCocoaController downJSCocoaHashCount];
	}
	[JSCocoaController downInstanceCount:self];

	// Dynamic super call
	id parentClass = [[JSCocoaController sharedController] parentObjCClassOfClassName:[NSString stringWithUTF8String:class_getName([self class])]];
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
		BOOL isSplitCall = [[JSCocoaController sharedController] trySplitCall:&splitMethodName class:self argumentCount:&argumentCount arguments:&arguments ctx:ctx];
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
	
	// Set it as new object
	JSObjectRef thisObject = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
	JSCocoaPrivateObject* private = JSObjectGetPrivate(thisObject);
	private.type = @"@";
	[private setObject:newInstance];
	
	// Create function object boxing our init method
	JSObjectRef function = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
	private = JSObjectGetPrivate(function);
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

/*

	Global resolver

*/
JSValueRef OSXObject_getProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef* exception)
{
	NSString*	propertyName = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, propertyNameJS);
	[NSMakeCollectable(propertyName) autorelease];
	
//	NSLog(@"Asking for global property %@", propertyName);
	
	//
	// ObjC class
	//
	Class objCClass = NSClassFromString(propertyName);
	if (objCClass)
	{
		JSObjectRef o = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
		JSCocoaPrivateObject* private = JSObjectGetPrivate(o);
		private.type = @"@";
		[private setObject:objCClass];		
		
		return	o;
	}

	id xml;
	id type = nil;
	//
	// Query BridgeSupport for property
	//
	xml = [[BridgeSupportController sharedController] queryName:propertyName];
	if (xml)
	{
		id error;
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


// Autocall : return value
JSValueRef valueOfCallback(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception)
{
//	NSLog(@"valueOf callback");
	// Holding a native JS value ? Return it
	JSCocoaPrivateObject* thisPrivateObject = JSObjectGetPrivate(thisObject);
	if ([thisPrivateObject.type isEqualToString:@"jsValueRef"])	
	{
		return [thisPrivateObject jsValueRef];
	}

	// Convert to string
	NSString*	toString = [NSString stringWithFormat:@"%@", [thisPrivateObject.type isEqualToString:@"@"] ? [[thisPrivateObject object] description] : @"JSCocoaPrivateObject"];
//	JSStringRef jsToString = JSStringCreateWithUTF8CString([toString UTF8String]);
    JSStringRef jsToString = JSStringCreateWithCFString((CFStringRef)toString);
	JSValueRef jsValueToString = JSValueMakeString(ctx, jsToString);
	JSStringRelease(jsToString);
//	NSLog(@"valueOf callback %@", toString);
	return	jsValueToString;
//	return	JSValueMakeNull(ctx);
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
	// Immediate release if dealloc is not overloaded
	[private release];
#ifdef __OBJC_GC__
// Mark internal object as collectable
[[NSGarbageCollector defaultCollector] enableCollectorForPointer:private];
#endif
}



//
// getProperty
//	Return property in object's internal hash if its contains propertyName
//	else ...
//	Get objC method matching propertyName, autocall it
//	else ...
//	method may be a split call -> return a private object
//
//	At method start, handle special cases for arrays (integers, length) and dictionaries
//
static JSValueRef GC_jsCocoaObject_getProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef* exception)
{
	NSString*	propertyName = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, propertyNameJS);
	[NSMakeCollectable(propertyName) autorelease];
	
	// Autocall instance
	if ([propertyName isEqualToString:@"thisObject"])	return	NULL;
	[JSCocoaController ensureJSValueIsObjectAfterInstanceAutocall:object inContext:ctx];
	
	JSCocoaPrivateObject* privateObject = JSObjectGetPrivate(object);
//	NSLog(@"Asking for property %@ %@(%@)", propertyName, privateObject, privateObject.type);

	if ([privateObject.type isEqualToString:@"@"])
	{
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
		
		
	
		// Check object's internal property in its jsHash
		id callee	= [privateObject object];
		if ([callee respondsToSelector:@selector(JSValueForJSName:)])
		{
//			JSValueRef hashProperty = [callee JSValueForJSName:propertyNameJS];

			JSValueRefAndContextRef	name = { JSValueMakeNull(ctx), NULL } ;
			name.value = JSValueMakeString(ctx, propertyNameJS);
			JSValueRef hashProperty = [callee JSValueForJSName:name].value;
			if (hashProperty && !JSValueIsNull(ctx, hashProperty))	
			{
				return	hashProperty;
			}
		}

		
		//
		// Attempt Zero arg autocall
		// Object.alloc().init() -> Object.alloc.init
		//
		BOOL useAutoCall = JSCocoaSingleton ? [[JSCocoaController sharedController] useAutoCall] : YES;
		if (useAutoCall)
		{
			id callee	= [privateObject object];
			SEL sel		= NSSelectorFromString(propertyName);
			// Go for zero arg call
			if ([propertyName rangeOfString:@":"].location == NSNotFound && [callee respondsToSelector:sel])
			{
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
//				NSLog(@"autocallpropName = %@ %x %x", propertyName, jsReturnValue, *(void**)[returnValue storage]);
/*				
				// When returning NULL or numbers, return value won't be an object — box it
				if (jsReturnValue == NULL || JSValueGetType(ctx, jsReturnValue) != kJSTypeObject)
				{
					JSObjectRef jsObject = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
					
					// Store our converted js value
					JSCocoaPrivateObject* privateObject = JSObjectGetPrivate(jsObject);
					[privateObject setType:@"jsValueRef"];
					[privateObject setJSValueRef:jsReturnValue ctx:ctx];
					jsReturnValue = jsObject;
				}

				// If return value is an object, set a valueOf callback on it
				if (JSValueGetType(ctx, jsReturnValue) == kJSTypeObject)
				{
					JSObjectRef jsObject = JSValueToObject(ctx, jsReturnValue, NULL);
					// Set the valueOf callback : JavascriptCore will call it when requesting default value
					[JSCocoaController setValueOfCallBackOnJSObject:jsObject inContext:ctx];
				}
				
				id o = JSObjectGetPrivate(JSValueToObject(ctx, jsReturnValue, NULL));
				[o setIsAutoCall:YES];
*/				
				if (jsReturnValue == nil)	return	JSValueMakeNull(ctx);
				// If return value is an object, set a valueOf callback on it
				if (JSValueGetType(ctx, jsReturnValue) == kJSTypeObject)
				{
					JSObjectRef jsObject = JSValueToObject(ctx, jsReturnValue, NULL);
					// Set the valueOf callback : JavascriptCore will call it when requesting default value
					[JSCocoaController setValueOfCallBackOnJSObject:jsObject inContext:ctx];
				}
				

				return	jsReturnValue;
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
				JSValueRef result;
				while (class)
				{
					id script = [NSString stringWithFormat:@"__globalJSFunctionRepository__.%@.%@", class, propertyName];
//					NSLog(@"%@", script);
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
				// Try split start
				BOOL isMaybeSplit = [[JSCocoaController sharedController] isMaybeSplitCall:methodName forClass:[callee class]];
				// If not split and not NSString, return (if NSString, try to convert to JS string in callAsFunction and use native JS methods)
				if (!isMaybeSplit && ![callee isKindOfClass:[NSString class]])	
				{
//					NSLog(@"NON SPLIT %@.%@", callee, methodName);
					return	NULL;
				}
			}
		}

		// Get ready for method call
		JSObjectRef o = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
		JSCocoaPrivateObject* private = JSObjectGetPrivate(o);
		private.type = @"method";
		private.methodName = methodName;
		
		/*
			setting valueOf allows us to return NULL when conversion is being done, eg 'string' + obj.property -> valueOf is called and returns NULL if property is a split call.
			BUT JSObject::toBoolean always returns true, therefore even !!(new Object(false)) returns true : 
			this will yield false positives for properties that are detected as things that could be split calls but aren't.
		*/
		[JSCocoaController setValueOfCallBackOnJSObject:o inContext:ctx];

		// Special case for instance : setup a valueOf callback calling instance
		if ([callee class] == callee && [propertyName isEqualToString:@"instance"])
		{
			JSStringRef jsName = JSStringCreateWithUTF8CString("thisObject");
			JSObjectSetProperty(ctx, o, jsName, object, JSCocoaInternalAttribute, NULL);
			JSStringRelease(jsName);
		}

	
		return	o;
	}
	
	return	NULL;
}
// GC stub
static JSValueRef jsCocoaObject_getProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef* exception)
{
#ifdef __OBJC_GC__
//[[NSGarbageCollector defaultCollector] disable];
#endif
	JSValueRef returnValue = GC_jsCocoaObject_getProperty(ctx, object, propertyNameJS, exception);
#ifdef __OBJC_GC__
//[[NSGarbageCollector defaultCollector] enable];
#endif
	return	returnValue;
}


//
// setProperty
//	call setter : propertyName -> setPropertyName
//
static bool GC_jsCocoaObject_setProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef jsValue, JSValueRef* exception)
{
	// Autocall : ensure 'instance' has been called and we've got our new instance
	[JSCocoaController ensureJSValueIsObjectAfterInstanceAutocall:object inContext:ctx];
	
	
	JSCocoaPrivateObject* privateObject = JSObjectGetPrivate(object);

	NSString*	propertyName = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, propertyNameJS);
	[NSMakeCollectable(propertyName) autorelease];
	
//	if ([privateObject.type  isEqualToString:@"struct"])
//	{
//		NSLog(@"****SET %@ in ctx %x on object %x (type=%@) method=%@", propertyName, ctx, object, privateObject.type, privateObject.methodName);
//	}
	
//	NSLog(@"****SET %@ in ctx %x on object %x (type=%@) method=%@", propertyName, ctx, object, privateObject.type, privateObject.methodName);
	if ([privateObject.type isEqualToString:@"@"])
	{

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
		
		
		
		// Try shorthand overload : obc[selector] = function
		id callee	= [privateObject object];
		if ([propertyName rangeOfString:@":"].location != NSNotFound)
		{
			JSValueRefAndContextRef v = { jsValue, ctx };
			[[JSCocoaController sharedController] overloadInstanceMethod:propertyName class:[callee class] jsFunction:v];
			return	true;
		}
		
		
		// Can't use capitalizedString on the whole string as it will transform 
		//			myValue 
		// to		Myvalue
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
			Method method = class_getInstanceMethod([callee class], sel);
			if (!method)	method = class_getClassMethod([callee class], sel);

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
			JSValueRefAndContextRef value = { JSValueMakeNull(ctx), NULL };
			value.value = jsValue;

			JSValueRefAndContextRef	name = { JSValueMakeNull(ctx), NULL } ;
			name.value = JSValueMakeString(ctx, propertyNameJS);
			BOOL set = [callee setJSValue:value forJSName:name];
			if (set)	return	true;
		}
	}

	// Special case for autocall : allow current js object to receive a custom valueOf method that will handle autocall
	// And a thisObject property holding class for instance autocall
	if ([propertyName isEqualToString:@"valueOf"])		return	false;
	if ([propertyName isEqualToString:@"thisObject"])	return	false;

	// ## Setter should fail AND WARN if propertyName can't be set. 
	// Warning is disabled as set on structures need a special check, yet to be written
//	return	throwException(ctx, exception, [NSString stringWithFormat:@"(in setter) object does not support setting"]), false;
	return	false;
}
// GC stub
static bool jsCocoaObject_setProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef jsValue, JSValueRef* exception)
{
#ifdef __OBJC_GC__
//[[NSGarbageCollector defaultCollector] disable];
#endif
	bool returnValue = GC_jsCocoaObject_setProperty(ctx, object, propertyNameJS, jsValue, exception);
#ifdef __OBJC_GC__
//[[NSGarbageCollector defaultCollector] enable];
#endif
	return	returnValue;
}


//
// deleteProperty
//	delete property in hash
//
static bool GC_jsCocoaObject_deleteProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef* exception)
{
	NSString*	propertyName = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, propertyNameJS);
	[NSMakeCollectable(propertyName) autorelease];
	
	JSCocoaPrivateObject* privateObject = JSObjectGetPrivate(object);
//	NSLog(@"Deleting property %@", propertyName);

	if (![privateObject.type isEqualToString:@"@"])	return false;

	id callee	= [privateObject object];
	if (![callee respondsToSelector:@selector(setJSValue:forJSName:)])	return	false;
	JSValueRefAndContextRef	name = { JSValueMakeNull(ctx), NULL } ;
	name.value = JSValueMakeString(ctx, propertyNameJS);
	return [callee deleteJSValueForJSName:name];
}
// GC stub
static bool jsCocoaObject_deleteProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef* exception)
{
#ifdef __OBJC_GC__
//[[NSGarbageCollector defaultCollector] disable];
#endif
	bool returnValue = GC_jsCocoaObject_deleteProperty(ctx, object, propertyNameJS, exception);
#ifdef __OBJC_GC__
//[[NSGarbageCollector defaultCollector] enable];
#endif
	return	returnValue;
}



//
// getPropertyNames
//	enumerate dictionary keys
//
static void GC_jsCocoaObject_getPropertyNames(JSContextRef ctx, JSObjectRef object, JSPropertyNameAccumulatorRef propertyNames)
{
	// Autocall : ensure 'instance' has been called and we've got our new instance
	[JSCocoaController ensureJSValueIsObjectAfterInstanceAutocall:object inContext:ctx];
	
	
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
// GC stub
static void jsCocoaObject_getPropertyNames(JSContextRef ctx, JSObjectRef object, JSPropertyNameAccumulatorRef propertyNames)
{
#ifdef __OBJC_GC__
//[[NSGarbageCollector defaultCollector] disable];
#endif
	GC_jsCocoaObject_getPropertyNames(ctx, object, propertyNames);
#ifdef __OBJC_GC__
//[[NSGarbageCollector defaultCollector] enable];
#endif
}




//
// callAsFunction
//	enumerate dictionary keys
//
static JSValueRef _jsCocoaObject_callAsFunction(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, JSValueRef arguments[], JSValueRef* exception, NSString* superSelector, Class superSelectorClass, JSValueRef** argumentsToFree);

//
// This method handles Super by retrieving the method name to call
//
static JSValueRef GC_jsCocoaObject_callAsFunction(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception)
{
	JSCocoaPrivateObject* privateObject		= JSObjectGetPrivate(function);
	JSCocoaPrivateObject* thisPrivateObject = JSObjectGetPrivate(thisObject);
	JSValueRef*	superArguments = NULL;
	id	superSelector = NULL;
	id	superSelectorClass = NULL;
/*
	// Zero arg autocall
	if ([privateObject isAutoCall])		
	{
		// Non kJSTypeObject return values, converted to a native JS type (number), boxed for auto call
		if ([privateObject.type isEqualToString:@"jsValueRef"])	
		{
			// Returning NULL will crash, return jsNULL
			if (![privateObject jsValueRef])	return	JSValueMakeNull(ctx);
			return [privateObject jsValueRef];
		}
		// Boxed objects
		return	function;
	}
*/
	if ([privateObject jsValueRef] && [privateObject.type isEqualToString:@"jsFunction"])
	{
		JSObjectRef jsFunction = JSValueToObject(ctx, [privateObject jsValueRef], NULL);
		return	JSObjectCallAsFunction(ctx, jsFunction, thisObject, argumentCount, arguments, exception);
	}
	// Javascript custom methods
	if ([privateObject.methodName isEqualToString:@"toString"] || [privateObject.methodName isEqualToString:@"valueOf"])
	{
		// Custom handling for NSNumber
		if ([privateObject.methodName isEqualToString:@"valueOf"] && [thisPrivateObject.object isKindOfClass:[NSNumber class]])
		{
			return	JSValueMakeNumber(ctx, [thisPrivateObject.object doubleValue]);
		}
		// Convert everything else to string
		NSString*	toString = [NSString stringWithFormat:@"%@", [thisPrivateObject.type isEqualToString:@"@"] ? [[thisPrivateObject object] description] : @"JSCocoaPrivateObject"];
//		JSStringRef jsToString = JSStringCreateWithUTF8CString([toString UTF8String]);
		JSStringRef jsToString = JSStringCreateWithCFString((CFStringRef)toString);
		JSValueRef jsValueToString = JSValueMakeString(ctx, jsToString);
		JSStringRelease(jsToString);
		return	jsValueToString;
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
#ifdef __OBJC_GC__
//[[NSGarbageCollector defaultCollector] disableCollectorForPointer:superArguments];
#endif
			for (i=0; i<superArgumentCount; i++)
				superArguments[i] = JSObjectGetPropertyAtIndex(ctx, argumentObject, i, NULL);
		}
		
		argumentCount = superArgumentCount;
		
		// Get method name and associated class (need class for obj_msgSendSuper)
		JSStringRef	jsCalleeName = JSStringCreateWithUTF8CString("callee");
		JSValueRef	jsCalleeValue = JSObjectGetProperty(ctx, argumentObject, jsCalleeName, NULL);
		JSStringRelease(jsCalleeName);
		JSObjectRef jsCallee = JSValueToObject(ctx, jsCalleeValue, NULL);
		superSelector = [[JSCocoaController sharedController] selectorForJSFunction:jsCallee];
		if (!superSelector)	return	throwException(ctx, exception, @"Super couldn't find parent method"), NULL;
		superSelectorClass = [[[JSCocoaController sharedController] classForJSFunction:jsCallee] superclass];
	}

	JSValueRef* functionArguments	= superArguments ? superArguments : (JSValueRef*)arguments;
	JSValueRef*	argumentsToFree		= NULL;
	JSValueRef jsReturnValue = _jsCocoaObject_callAsFunction(ctx, function, thisObject, argumentCount, functionArguments, exception, superSelector, superSelectorClass, &argumentsToFree);
	
	if (superArguments)	
	{
		free(superArguments);
#ifdef __OBJC_GC__
//[[NSGarbageCollector defaultCollector] enableCollectorForPointer:arguments2];
#endif
	}
	if (argumentsToFree)	free(argumentsToFree);
	
	return	jsReturnValue;
}

//
// That's where the actual calling happens.
//
static JSValueRef _jsCocoaObject_callAsFunction(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, JSValueRef arguments[], JSValueRef* exception, NSString* superSelector, Class superSelectorClass, JSValueRef** argumentsToFree)
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
			//	set( { Value : '5', forKey : 'hello' } )
			//	-> setValue:forKey:
			//
			if (![callee respondsToSelector:NSSelectorFromString(methodName)])
			{
				id			splitMethodName		= privateObject.methodName;
				BOOL isSplitCall = [[JSCocoaController sharedController] trySplitCall:&splitMethodName class:[callee class] argumentCount:&argumentCount arguments:&arguments ctx:ctx];
				if (isSplitCall)		
				{
					methodName = splitMethodName;
					// trySplitCall returned new arguments that we'll need to free later on
					*argumentsToFree = arguments;
				}
			}
		}
		Method method = class_getInstanceMethod([callee class], NSSelectorFromString(methodName));
		if (!method)	method = class_getClassMethod([callee class], NSSelectorFromString(methodName));

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
	}
	
	// If argument count doesn't match, check if it's a variadic call
	// If it's not variadic, bail
	BOOL isVariadic = NO;
	if (callAddressArgumentCount != argumentCount)	
	{
		if (methodName)		isVariadic = [[JSCocoaController sharedController] isMethodVariadic:methodName class:[callee class]];
		else				isVariadic = [[JSCocoaController sharedController] isFunctionVariadic:functionName];
		
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
#ifdef __OBJC_GC__
//[[NSGarbageCollector defaultCollector] disableCollectorForPointer:args];
#endif
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
#ifndef JSCocoa_iPhone
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
			BOOL	converted = [arg fromJSValueRef:jsValue inContext:ctx];
			if (!converted)		return	throwException(ctx, exception, [NSString stringWithFormat:@"Argument %c not converted", [arg typeEncoding]]), NULL;
			args[idx]		= [arg ffi_type];
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
// GC stub
static JSValueRef jsCocoaObject_callAsFunction(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception)
{
#ifdef __OBJC_GC__
//[[NSGarbageCollector defaultCollector] disable];

//[[NSGarbageCollector defaultCollector] disableCollectorForPointer:arguments];
//for (int i=0; i<argumentCount; i++)	[[NSGarbageCollector defaultCollector] disableCollectorForPointer:arguments[i]];


#endif
	JSValueRef returnValue = GC_jsCocoaObject_callAsFunction(ctx, function, thisObject, argumentCount, arguments, exception);

#ifdef __OBJC_GC__
//[[NSGarbageCollector defaultCollector] enable];


//for (int i=0; i<argumentCount; i++)	[[NSGarbageCollector defaultCollector] enableCollectorForPointer:arguments[i]];
//[[NSGarbageCollector defaultCollector] enableCollectorForPointer:arguments];

#endif
	return	returnValue;
}



//
// Creating new structures with Javascript's new operator
//
//	// Zero argument call : fill with undefined
//	var p = new NSPoint					returns { origin : { x : undefined, y : undefined }, size : { width : undefined, height : undefined } }
//
//	// Initial values argument call : fills structure with arguments[] contents — THROWS exception if arguments.length != structure.elementCount 
//	var p = new NSPoint(1, 2, 3, 4)		returns { origin : { x : 1, y : 2 }, size : { width : 3, height : 4 } }
//
static JSObjectRef GC_jsCocoaObject_callAsConstructor(JSContextRef ctx, JSObjectRef constructor, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception)
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
// GC stub
static JSObjectRef jsCocoaObject_callAsConstructor(JSContextRef ctx, JSObjectRef constructor, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception)
{
#ifdef __OBJC_GC__
//[[NSGarbageCollector defaultCollector] disable];
#endif
	JSObjectRef returnValue = GC_jsCocoaObject_callAsConstructor(ctx, constructor, argumentCount, arguments, exception);
#ifdef __OBJC_GC__
//[[NSGarbageCollector defaultCollector] enable];
#endif
	return	returnValue;
}

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
	if ([[JSCocoaController sharedController] logAllExceptions])
	{
		NSLog(@"JSCocoa exception : %@", reason);
		if ([[JSCocoaController sharedController] isSpeaking])	system([[NSString stringWithFormat:@"say \"%@\" &", reason] UTF8String]);
	}

	JSStringRef jsName = JSStringCreateWithUTF8CString([reason UTF8String]);
	JSValueRef jsString = JSValueMakeString(ctx, jsName);
	JSStringRelease(jsName);
	*exception	= jsString;
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
// JSCocoa shorthand
//
@implementation JSCocoa
@end