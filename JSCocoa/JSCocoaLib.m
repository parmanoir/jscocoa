//
//  JSCocoaLib.m
//  JSCocoa
//
//  Created by Patrick Geiller on 21/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "JSCocoaLib.h"


//
// Handles out arguments of functions and methods.
//	eg NSOpenGLGetVersion(int*, int*) asks for two pointers to int.
//	JSCocoaOutArgument will alloc the memory through JSCocoaFFIArgument and get the result back to Javascript (check out value in JSCocoaController)
//
@implementation JSCocoaOutArgument

- (id)init
{
	self	= [super init];

	arg		= nil;
	buffer	= nil;
	return self;
}
- (void)cleanUp
{
	[arg release];
	[buffer release];
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
// convert the out value to a JSValue
//
- (JSValueRef)outJSValueRefInContext:(JSContextRef)ctx
{
//	[[NSGarbageCollector defaultCollector] disable];
	JSValueRef jsValue = NULL;
	[arg toJSValueRef:&jsValue inContext:ctx];
//	[[NSGarbageCollector defaultCollector] enable];
	return	jsValue;
}

//
//	JSCocoaOutArgument holds a JSCocoaFFIArgument around.
//	it stays alive after ffi_call and can be queried by Javascript for type modifier values.
//	
- (BOOL)mateWithJSCocoaFFIArgument:(JSCocoaFFIArgument*)_arg
{
//	NSLog(@"outArgument %x starting up encoding=%c(%@)", self, [_arg typeEncoding], [_arg pointerTypeEncoding]);
	// If holding a memory buffer, use its pointer
	if (buffer)
	{
		arg	= _arg;
		[arg retain];
		void* ptr = [buffer pointerForIndex:bufferIndex];
		if (!ptr)	return	NO;
//		NSLog(@"mating encoding ***%c***%c***(pointerTypeEncoding=%@) on arg %x", [arg typeEncoding], [buffer typeAtIndex:bufferIndex], [arg pointerTypeEncoding], _arg);
//		[arg setTypeEncoding:[buffer typeAtIndex:bufferIndex] withCustomStorage:ptr];
		[arg setTypeEncoding:[arg typeEncoding] withCustomStorage:ptr];
		return	YES;
	}

	// Standard pointer
	if (![_arg allocatePointerStorage])	return	NO;

	arg	= _arg;
	[arg retain];
	return	YES;
}

- (BOOL)mateWithMemoryBuffer:(id)b atIndex:(int)idx
{
	if (!b || ![b isKindOfClass:[JSCocoaMemoryBuffer class]])	return	NSLog(@"mateWithMemoryBuffer called without a memory buffer (%@)", b), NO;
	buffer = b;
	[buffer retain];
	bufferIndex = idx;
	return	YES;
}

@end



//
// Instead of malloc(sizeof(float)*4), JSCocoaMemoryBuffer expects 'ffff' as an init string.
//	The buffer can be manipulated like an array (buffer[2] = 0.5) 
//		* it can be filled, calling methods to copy data in it
//			- (NSBezierPathElement)elementAtIndex:(NSInteger)index associatedPoints:(NSPointArray)points;
//		* it can be used as data source, calling methods to copy data from it
//			- (void)setAssociatedPoints:(NSPointArray)points atIndex:(NSInteger)index;
//
@implementation JSCocoaMemoryBuffer

+ (id)bufferWithTypes:(id)types
{
	return [[[JSCocoaMemoryBuffer alloc] initWithTypes:types] autorelease];
}


- (id)initWithTypes:(id)_types
{
	self	= [super init];
	buffer	= NULL;

	// Copy types string
	typeString = [NSString stringWithString:_types];
	[typeString retain];

	// Compute buffer size
	const char* types = [typeString UTF8String];
	int l = [typeString length];
	bufferSize = 0;
	for (int i=0; i<l; i++)
	{
		int size = [JSCocoaFFIArgument sizeOfTypeEncoding:types[i]];
		if (size == -1)	return	NSLog(@"JSCocoaMemoryBuffer initWithTypes : unknown type %c", types[i]), self;
		bufferSize += size;
	}

	// Malloc
//	NSLog(@"mallocing %d bytes for %@", bufferSize, typeString);
	buffer = malloc(bufferSize);
	
	return	self;
}

- (void)dealloc	
{
	if (buffer)	free(buffer);
	[typeString release];
	[super dealloc];
}
- (void)finalize
{
	if (buffer)	free(buffer);
	[super finalize];
}

//
// Returns pointer for index without any padding
//
- (void*)pointerForIndex:(int)index
{
	const char* types = [typeString UTF8String];
	void* pointedValue = buffer;
	for (int i=0; i<index; i++)
	{
//		NSLog(@"advancing %c", types[i]);
		[JSCocoaFFIArgument advancePtr:&pointedValue accordingToEncoding:types[i]];
	}
	return	pointedValue;
}

- (char)typeAtIndex:(int)index
{
	if (index >= [typeString length])	return '\0';
	return	[typeString UTF8String][index];
}

- (int)typeCount
{
	return	[typeString length];
}


//
// Using JSValueRefAndContextRef as input to get the current context in which to create the return value
//
- (JSValueRef)valueAtIndex:(int)index inContext:(JSContextRef)ctx
{
	char	typeEncoding = [self typeAtIndex:index];
	void*	pointedValue = [self pointerForIndex:index];

	JSValueRef returnValue;
	[JSCocoaFFIArgument toJSValueRef:&returnValue inContext:ctx typeEncoding:typeEncoding fullTypeEncoding:nil fromStorage:pointedValue];
	return	returnValue;
}

- (BOOL)setValue:(JSValueRef)jsValue atIndex:(int)index inContext:(JSContextRef)ctx;
{
	char	typeEncoding = [self typeAtIndex:index];
	void*	pointedValue = [self pointerForIndex:index];
//NSLog(@"JSCocoaMemoryBuffer.setValue at %d", index);
	[JSCocoaFFIArgument fromJSValueRef:jsValue inContext:ctx typeEncoding:typeEncoding fullTypeEncoding:nil fromStorage:pointedValue];
	return	YES;
}


@end



@implementation JSCocoaLib

//
// Classes are returned as strings, as sometimes adding them to an array crashes
//
+ (NSArray*)classes
{
	int classCount		= objc_getClassList(nil, 0);
	Class* classList	= malloc(sizeof(Class)*classCount);
	objc_getClassList(classList, classCount);
	
	
	NSMutableArray* classArray	= [NSMutableArray array];
	for (int i=0; i<classCount; i++)
	{
		id class		= classList[i];
		const char* name= class_getName(class);
		if (!name)		continue;
		id className	= [NSString stringWithUTF8String:name];
//		NSLog(@">>class %@", className);
		if ([className hasPrefix:@"_NSZombie_"] 
		||	[className isEqualToString:@"Object"]
		||	[className isEqualToString:@"List"]
//		||	[className isEqualToString:@"NSMessageBuilder"]
//		||	[className isEqualToString:@"NSLeafProxy"]
//		||	[className isEqualToString:@"__NSGenericDeallocHandler"]
		)
		{
//			NSLog(@"skipping %@", className);
			continue;
		}
		[classArray addObject:className];

	}

	free(classList);
	
	return	classArray;
}

+ (NSArray*)rootclasses
{
	id classes = [self classes];
	NSMutableArray* classArray	= [NSMutableArray array];
	for (id className in classes)
	{
		id class = objc_getClass([className UTF8String]);
		id superclass = class_getSuperclass(class);
		if (superclass)	continue;

		[classArray addObject:className];
	}
	return	classArray;
}

@end


@implementation NSObject(ClassWalker)

//
// Returns which framework containing the class
//
+ (id)classImage
{
	const char* name = class_getImageName(self);
	if (!name)	return	nil;
	return	[NSString stringWithUTF8String:name];
}
- (id)classImage
{	
	return [[self class] classImage];
}


//
// Derivation path
//	derivationPath(NSButton) = NSObject, NSResponder, NSView, NSControl, NSButton
//
+ (id)derivationPath
{
	int level = -1;
	id class = self;
	id classes = [NSMutableArray array];
	while (class)
	{
		[classes insertObject:class atIndex:0];
		level++;
		class = [class superclass];
	}
	return	classes;
}
- (id)derivationPath
{
	return [[self class] derivationPath];
}

//
// Derivation level
//
+ (int)derivationLevel
{
	return [[self derivationPath] count]-1;
}
- (int)derivationLevel
{
	return [[self class] derivationLevel];
}

//
// Methods
//

// Copy all class or instance (type) methods of a class in an array
static id copyMethods(Class class, NSMutableArray* array, NSString* type)
{
	unsigned int methodCount;
	if ([type isEqualToString:@"class"])
		class = objc_getMetaClass(class_getName(class));

	Method* methods = class_copyMethodList(class, &methodCount);
	for (int i=0; i<methodCount; i++)
	{
		Method m	= methods[i];
		Dl_info info;
		dladdr(method_getImplementation(m), &info);

		id name		= NSStringFromSelector(method_getName(m));
		id encoding	= [NSString stringWithUTF8String:method_getTypeEncoding(m)];
		id framework= [NSString stringWithUTF8String:info.dli_fname];
		
		id hash = [NSDictionary dictionaryWithObjectsAndKeys:
			name,		@"name",
			encoding,	@"encoding",
			type,		@"type",
			class,		@"class",
			framework, @"framework",
			nil];
			
		[array addObject:hash];
	}
	free(methods);
	return	array;
}
+ (id)ownMethods
{
	id methods = [NSMutableArray array];
	copyMethods([self class], methods, @"class");
	copyMethods([self class], methods, @"instance");
	return methods;
}
- (id)ownMethods
{
	return [[self class] ownMethods];
}
+ (id)methods
{
	id classes	= [self derivationPath];
	id methods	= [NSMutableArray array];
	for (id class in classes)
	{
		id m = [class ownMethods];
		[methods addObjectsFromArray:m];
	}
	return	methods;
}
- (id)methods
{
	return [[self class] methods];
}


@end
		
		// Handle 
		//	_superclass
		//	_derivationLevel
		//	_subclasses
		//	_ownSubclasses 
		//	_methods
		//	_ownMethods
		//	_ivars _properties
