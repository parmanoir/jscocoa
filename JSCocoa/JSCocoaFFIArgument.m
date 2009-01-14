//
//  JSCocoaFFIArgument.m
//  JSCocoa
//
//  Created by Patrick Geiller on 14/07/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "JSCocoaFFIArgument.h"
#import "JSCocoaController.h"
#import "JSCocoaPrivateObject.h"
#import <objc/runtime.h>


#ifdef JSCocoa_iPhone
#import "GDataDefines.h"
#import "GDataXMLNode.h"
#endif

@implementation JSCocoaFFIArgument

- (id)init
{
	id o	= [super init];

	ptr				= NULL;
	typeEncoding	= 0;
	isReturnValue	= NO;
	ownsStorage		= YES;
	
	structureTypeEncoding	= nil;
	structureType.elements	= NULL;
	
	// Used to store string data while converting JSStrings to char*
	customData		= nil;
	
	return	o;
}

- (void)cleanUp
{
	if (ptr && ownsStorage)	free(ptr);
	if (customData)			[customData release];

	if (structureType.elements)	free(structureType.elements);
	ptr = NULL;
}

- (void)dealloc
{
	if (structureTypeEncoding) [structureTypeEncoding release];
	[self cleanUp];
	[super dealloc];
}
- (void)finalize
{
	if (structureTypeEncoding) [structureTypeEncoding release];
	[self cleanUp];
	[super finalize];
}



#pragma mark Getters / Setters

//
// Needed because libffi needs at least sizeof(long) as return value storage
//
- (void)setIsReturnValue:(BOOL)v
{
	isReturnValue = v;
}

- (char)typeEncoding
{
	return	typeEncoding;
}

- (void)setTypeEncoding:(char)encoding
{
	if ([JSCocoaFFIArgument sizeOfTypeEncoding:encoding] == -1)	{ NSLog(@"Bad type encoding %c", encoding); return; };

	typeEncoding = encoding;
	[self allocateStorage];	
}

- (void)setTypeEncoding:(char)encoding withCustomStorage:(void*)storagePtr
{
	typeEncoding	= encoding;
	ownsStorage		= NO;
	ptr				= storagePtr;
}

- (NSString*)structureTypeEncoding
{
	return	structureTypeEncoding;
}

- (void)setStructureTypeEncoding:(NSString*)encoding
{
	[self setStructureTypeEncoding:encoding withCustomStorage:NULL];
}

- (void)setStructureTypeEncoding:(NSString*)encoding withCustomStorage:(void*)storagePtr
{
	typeEncoding = '{';
	structureTypeEncoding = [[NSString alloc] initWithString:encoding];
	if (storagePtr)
	{
		ownsStorage		= NO;
		ptr				= storagePtr;
	}
	else	[self allocateStorage];

	id types = [JSCocoaFFIArgument typeEncodingsFromStructureTypeEncoding:encoding];
	int elementCount = [types count];

	//
	// Build FFI type
	//
	structureType.size	= 0;
	structureType.alignment	= 0;
	structureType.type	= FFI_TYPE_STRUCT;
	structureType.elements = malloc(sizeof(ffi_type*)*(elementCount+1));	// +1 is trailing NULL

	int i = 0;
	for (id type in types)
	{
		char encoding = *(char*)[type UTF8String];
		structureType.elements[i++] = [JSCocoaFFIArgument ffi_typeForTypeEncoding:encoding];
	}
	structureType.elements[elementCount] = NULL;
}




- (ffi_type*)ffi_type
{
	if (!typeEncoding)	return	NULL;

	if (typeEncoding == '{')	return	&structureType;

	return	[JSCocoaFFIArgument ffi_typeForTypeEncoding:typeEncoding];
}


#pragma mark Storage 

- (void*)allocateStorage
{
	if (!typeEncoding)	return	NULL;
	
	[self cleanUp];
	// Special case for structs
	if (typeEncoding == '{')
	{
//		NSLog(@"allocateStorage: Allocating struct");
		// Some front padding for alignment and tail padding for structure
		// (http://developer.apple.com/documentation/DeveloperTools/Conceptual/LowLevelABI/Articles/IA32.html)
		// Structures are tail-padded to 32-bit multiples.
		
		//	+16 for alignment
		//	+4 for tail padding
		ptr = malloc([JSCocoaFFIArgument sizeOfStructure:structureTypeEncoding] + 16 + 4); 
		return	ptr;
	}
	
	int size = [JSCocoaFFIArgument sizeOfTypeEncoding:typeEncoding];

	// Bail if we can't handle our type
	if (size == -1)	return	NULL;
	if (size >= 0)	
	{
		int	minimalReturnSize = sizeof(long);
		if (isReturnValue && size < minimalReturnSize)	size = minimalReturnSize;
		ptr = malloc(size);
		memset(ptr, size, 1);
	}
//	NSLog(@"Allocated size=%d %x for object %@", size, ptr, self);
	return	ptr;
}

- (void**)storage
{
	if (typeEncoding == '{')
	{
		int alignOnSize = 16;
		
		int address = (int)ptr;
		if ((address % alignOnSize) != 0)
			address = (address+alignOnSize) & ~(alignOnSize-1);
		return (void**)address;
	}

	return ptr;
}


+ (void)alignPtr:(void**)ptr accordingToEncoding:(char)encoding
{
	int alignOnSize = [JSCocoaFFIArgument alignmentOfTypeEncoding:encoding];
	
	int address = (int)*ptr;
	if ((address % alignOnSize) != 0)
		address = (address+alignOnSize) & ~(alignOnSize-1);
//	NSLog(@"alignOf(%c)=%d", encoding, alignOnSize);

	*ptr = (void*)address;
}

+ (void)advancePtr:(void**)ptr accordingToEncoding:(char)encoding
{
	int address = (int)*ptr;
	address += [JSCocoaFFIArgument sizeOfTypeEncoding:encoding];
	*ptr = (void*)address;
}


#pragma mark Conversion

//
// Convert from js value
//
- (BOOL)fromJSValueRef:(JSValueRef)value inContext:(JSContextRef)ctx
{
	BOOL r = [JSCocoaFFIArgument fromJSValueRef:value inContext:ctx withTypeEncoding:typeEncoding withStructureTypeEncoding:structureTypeEncoding fromStorage:ptr];
	if (!r)	
	{
		NSLog(@"fromJSValueRef FAILED, jsType=%d encoding=%c structureEncoding=%@", JSValueGetType(ctx, value), typeEncoding, structureTypeEncoding);
	}
	return r;
}

+ (BOOL)fromJSValueRef:(JSValueRef)value inContext:(JSContextRef)ctx withTypeEncoding:(char)typeEncoding withStructureTypeEncoding:(NSString*)structureTypeEncoding fromStorage:(void*)ptr;
{
	if (!typeEncoding)	return	NO;

//	JSType type = JSValueGetType(ctx, value);
//	NSLog(@"JSType=%d encoding=%c self=%x", type, typeEncoding, self);

	switch  (typeEncoding)
	{
		case	_C_ID:	
		case	_C_CLASS:
		{
			return [self unboxJSValueRef:value toObject:ptr inContext:ctx];
		}
		
		case	_C_CHR:
		case	_C_UCHR:
		case	_C_SHT:
		case	_C_USHT:
		case	_C_INT:
		case	_C_UINT:
		case	_C_LNG:
		case	_C_ULNG:
		case	_C_LNG_LNG:
		case	_C_ULNG_LNG:
		case	_C_FLT:
		case	_C_DBL:
		{
			double number = JSValueToNumber(ctx, value, NULL);
//			NSLog(@"type=%d n=%f", type, number);

			switch  (typeEncoding)
			{
				case	_C_CHR:			*(char*)ptr = (char)number;								break;
				case	_C_UCHR:		*(unsigned char*)ptr = (unsigned char)number;			break;
				case	_C_SHT:			*(short*)ptr = (short)number;							break;
				case	_C_USHT:		*(unsigned short*)ptr = (unsigned short)number;			break;
				case	_C_INT:			
				{
#ifdef __BIG_ENDIAN__
					// Two step conversion : to unsigned int then to int. One step conversion fails on PPC.
					unsigned int uint = (unsigned int)number;
					*(signed int*)ptr = (signed int)uint;
					break;
#endif
#ifdef __LITTLE_ENDIAN__
					*(int*)ptr = (int)number;
					break;
#endif
				}
				case	_C_UINT:		*(unsigned int*)ptr = (unsigned int)number;				break;
				case	_C_LNG:			*(long*)ptr = (long)number;								break;
				case	_C_ULNG:		*(unsigned long*)ptr = (unsigned long)number;			break;
				case	_C_LNG_LNG:		*(long long*)ptr = (long long)number;					break;
				case	_C_ULNG_LNG:	*(unsigned long long*)ptr = (unsigned long long)number;	break;
				case	_C_FLT:			*(float*)ptr = (float)number;							break;
				case	_C_DBL:			*(double*)ptr = (double)number;							break;
			}
			return	YES;
		}
		case	'{':
		{
			// Special case for getting raw JSValues to ObjC
			BOOL isJSStruct = NSOrderedSame == [structureTypeEncoding compare:@"{JSValueRefAndContextRef" options:0 range:NSMakeRange(0, sizeof("{JSValueRefAndContextRef")-1)];
			if (isJSStruct)
			{
				// Beware ! This context is not the global context and will be valid only for that call.
				// Other uses (closures) use the global context via JSCocoaController.
				JSValueRefAndContextRef*	jsStruct = (JSValueRefAndContextRef*)ptr;
				jsStruct->value	= value;
				jsStruct->ctx	= ctx;
				return	YES;
			}

			if (!JSValueIsObject(ctx, value))	return	NO;
			JSObjectRef object = JSValueToObject(ctx, value, NULL);

			void* p = ptr;
			id type = [JSCocoaFFIArgument structureFullTypeEncodingFromStructureTypeEncoding:structureTypeEncoding];
			int numParsed =	[JSCocoaFFIArgument structureFromJSObjectRef:object inContext:ctx inParentJSValueRef:NULL fromCString:(char*)[type UTF8String] fromStorage:&p];
			return	numParsed;
		}
		case	_C_SEL:
		{
			id str = NSStringFromJSValue(value, ctx);
			*(SEL*)ptr = NSSelectorFromString(str);
			return	YES;
		}
		case	_C_CHARPTR:
		{
			id str = NSStringFromJSValue(value, ctx);
//TAG BAD CONVERSION NOT ALIVE LONG ENOUGH
			*(char**)ptr = (char*)[str UTF8String];
			return	YES;
		}
		case	_C_BOOL:
		{
			bool b = JSValueToBoolean(ctx, value);
			*(BOOL*)ptr = b;
			return	YES;
		}
		
		case	_C_PTR:
		{
			return [self unboxJSValueRef:value toObject:ptr inContext:ctx];
		}
		
	}
	return	NO;
}


//
// Convert to js value
//
- (BOOL)toJSValueRef:(JSValueRef*)value inContext:(JSContextRef)ctx
{
	void* p = ptr;
#ifdef __BIG_ENDIAN__
	long	v;
	// Return value was padded, need to do some shifting on PPC
	if (isReturnValue)
	{
		int size = [JSCocoaFFIArgument sizeOfTypeEncoding:typeEncoding];
		int paddedSize = sizeof(long);
		
		if (size > 0 && size < paddedSize && paddedSize == 4)
		{
			v = *(long*)ptr;
			v = CFSwapInt32(v);
			p = &v;
		}
	}
#endif	
	BOOL r = [JSCocoaFFIArgument toJSValueRef:value inContext:ctx withTypeEncoding:typeEncoding withStructureTypeEncoding:structureTypeEncoding fromStorage:p];
	if (!r)	NSLog(@"toJSValueRef FAILED");
	return	r;
}


+ (BOOL)toJSValueRef:(JSValueRef*)value inContext:(JSContextRef)ctx withTypeEncoding:(char)typeEncoding withStructureTypeEncoding:(NSString*)structureTypeEncoding fromStorage:(void*)ptr
{
	if (!typeEncoding)	return	NO;
	
//	NSLog(@"toJSValueRef: %c", typeEncoding);
	switch  (typeEncoding)
	{
		case	_C_ID:	
		case	_C_CLASS:
		{
			id objcObject = *(id*)ptr;
			return	[self boxObject:(id)objcObject toJSValueRef:value inContext:ctx];

		}
		
		case	_C_VOID: 
			return	YES;

		case	_C_CHR:
		case	_C_UCHR:
		case	_C_SHT:
		case	_C_USHT:
		case	_C_INT:
		case	_C_UINT:
		case	_C_LNG:
		case	_C_ULNG:
		case	_C_LNG_LNG:
		case	_C_ULNG_LNG:
		case	_C_FLT:
		case	_C_DBL:
		{
			double number;
			switch  (typeEncoding)
			{
				case	_C_CHR:			number = *(char*)ptr;				break;
				case	_C_UCHR:		number = *(unsigned char*)ptr;		break;
				case	_C_SHT:			number = *(short*)ptr;				break;
				case	_C_USHT:		number = *(unsigned short*)ptr;		break;
				case	_C_INT:			number = *(int*)ptr;				break;
				case	_C_UINT:		number = *(unsigned int*)ptr;		break;
				case	_C_LNG:			number = *(long*)ptr;				break;
				case	_C_ULNG:		number = *(unsigned long*)ptr;		break;
				case	_C_LNG_LNG:		number = *(long long*)ptr;			break;
				case	_C_ULNG_LNG:	number = *(unsigned long long*)ptr;	break;
				case	_C_FLT:			number = *(float*)ptr;				break;
				case	_C_DBL:			number = *(double*)ptr;				break;
			}
			*value = JSValueMakeNumber(ctx, number);
			return	YES;
		}
		
		
		case	'{':
		{
			// Special case for getting raw JSValues from ObjC to JS
			BOOL isJSStruct = NSOrderedSame == [structureTypeEncoding compare:@"{JSValueRefAndContextRef" options:0 range:NSMakeRange(0, sizeof("{JSValueRefAndContextRef")-1)];
			if (isJSStruct)
			{
				JSValueRefAndContextRef*	jsStruct = (JSValueRefAndContextRef*)ptr;
				*value = jsStruct->value;
				return	YES;
			}
		
			void* p = ptr;
			id type = [JSCocoaFFIArgument structureFullTypeEncodingFromStructureTypeEncoding:structureTypeEncoding];
			// Bail if structure not found
			if (!type)	return	0;

			JSObjectRef jsObject = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
			JSCocoaPrivateObject* private = JSObjectGetPrivate(jsObject);
			private.type = @"struct";
			int numParsed =	[JSCocoaFFIArgument structureToJSValueRef:value inContext:ctx fromCString:(char*)[type UTF8String] fromStorage:&p];
			return	numParsed;
		}

		case	_C_SEL:
		{
			SEL sel = *(SEL*)ptr;
			id str = NSStringFromSelector(sel);
//			JSStringRef jsName = JSStringCreateWithUTF8CString([str UTF8String]);
			JSStringRef	jsName = JSStringCreateWithCFString((CFStringRef)str);
			*value = JSValueMakeString(ctx, jsName);
			JSStringRelease(jsName);
			return	YES;
		}
		case	_C_BOOL:
		{
			BOOL b = *(BOOL*)ptr;
			*value = JSValueMakeBoolean(ctx, b);
			return	YES;
		}
		case	_C_CHARPTR:
		{
//			JSStringRef jsName = JSStringCreateWithUTF8CString(*(char**)ptr);
			NSString* name = [NSString stringWithUTF8String:*(char**)ptr];
			JSStringRef	jsName = JSStringCreateWithCFString((CFStringRef)name);
			*value = JSValueMakeString(ctx, jsName);
			JSStringRelease(jsName);
			return	YES;
		}
		
		case	_C_PTR:
		{
			JSObjectRef o = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
			JSCocoaPrivateObject* private = JSObjectGetPrivate(o);
			private.type = @"rawPointer";
			[private setRawPointer:*(void**)ptr];
			*value = o;
			return	YES;
		}
	}
	
	return	NO;
}

/*

	*value MUST be NULL to be receive allocated JSValue
	
*/
+ (int)structureToJSValueRef:(JSValueRef*)value inContext:(JSContextRef)ctx fromCString:(char*)c fromStorage:(void**)ptr
{
	return	[self structureToJSValueRef:value inContext:ctx fromCString:c fromStorage:ptr initialValues:nil initialValueCount:0 convertedValueCount:nil];
}

+ (int)structureToJSValueRef:(JSValueRef*)value inContext:(JSContextRef)ctx fromCString:(char*)c fromStorage:(void**)ptr initialValues:(JSValueRef*)initialValues initialValueCount:(int)initialValueCount convertedValueCount:(int*)convertedValueCount
{
	// Build new structure object
	JSObjectRef jsObject = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
	JSCocoaPrivateObject* private = JSObjectGetPrivate(jsObject);
	private.type = @"struct";
	private.structureName = [JSCocoaFFIArgument structureNameFromStructureTypeEncoding:[NSString stringWithUTF8String:c]];
	if (!*value)	*value = jsObject;

	char* c0 = c;
	// Skip '{'
	c += 1;
	// Skip '_' if it's there
	if (*c == '_') c++;
	// Skip structureName, '='
	c += [private.structureName length]+1;

	int	openedBracesCount = 1;
	int closedBracesCount = 0;
	for (; *c && closedBracesCount != openedBracesCount; c++)
	{
		if (*c == '{')	openedBracesCount++;
		if (*c == '}')	closedBracesCount++;
		// Parse name then type
		if (*c == '"')
		{
			char* c2 = c+1;
			while (c2 && *c2 != '"') c2++;
			id propertyName = [[[NSString alloc] initWithBytes:c+1 length:(c2-c-1) encoding:NSASCIIStringEncoding] autorelease];
			c = c2;
			
			// Skip '"'
			c++;
			char encoding = *c;
			
			JSValueRef	valueJS = NULL;
			if (encoding == '{')
			{
				int numParsed = [self structureToJSValueRef:&valueJS inContext:ctx fromCString:c fromStorage:ptr initialValues:initialValues initialValueCount:initialValueCount convertedValueCount:convertedValueCount];
				c += numParsed;
			}
			else
			{
				// If a pointer to raw C structure data is given, convert its members to JS values
				if (ptr)
				{
					// Align 
					[JSCocoaFFIArgument alignPtr:ptr accordingToEncoding:encoding];
					// Get value
					[JSCocoaFFIArgument toJSValueRef:&valueJS inContext:ctx withTypeEncoding:encoding withStructureTypeEncoding:nil fromStorage:*ptr];
					// Advance ptr
					[JSCocoaFFIArgument advancePtr:ptr accordingToEncoding:encoding];
				}
				else
				// No pointer ? Get values from initialValues array. If not present, create undefined values
				{
					if (!convertedValueCount)	return 0;
					if (initialValues && initialValueCount && *convertedValueCount < initialValueCount)	valueJS = initialValues[*convertedValueCount];
					else																				valueJS = JSValueMakeUndefined(ctx);									
				}
				if (convertedValueCount)	*convertedValueCount = *convertedValueCount+1;
			}
			JSStringRef	propertyNameJS = JSStringCreateWithCFString((CFStringRef)propertyName);
			JSObjectSetProperty(ctx, jsObject, propertyNameJS, valueJS, 0, NULL);
			JSStringRelease(propertyNameJS);
		}
	}
	return	c-c0-1;
}

+ (int)structureFromJSObjectRef:(JSObjectRef)object inContext:(JSContextRef)ctx inParentJSValueRef:(JSValueRef)parentValue fromCString:(char*)c fromStorage:(void**)ptr
{
	id structureName = [JSCocoaFFIArgument structureNameFromStructureTypeEncoding:[NSString stringWithUTF8String:c]];
	char* c0 = c;
	// Skip '{'
	c += 1;
	// Skip '_' if it's there
	if (*c == '_') c++;
	// Skip structureName, '='
	c += [structureName length]+1;

//	NSLog(@"%@", structureName);
	int	openedBracesCount = 1;
	int closedBracesCount = 0;
	for (; *c && closedBracesCount != openedBracesCount; c++)
	{
		if (*c == '{')	openedBracesCount++;
		if (*c == '}')	closedBracesCount++;
		// Parse name then type
		if (*c == '"')
		{
			char* c2 = c+1;
			while (c2 && *c2 != '"') c2++;
			id propertyName = [[[NSString alloc] initWithBytes:c+1 length:(c2-c-1) encoding:NSASCIIStringEncoding] autorelease];
			c = c2;
			
			// Skip '"'
			c++;
			char encoding = *c;
			
			JSStringRef propertyNameJS = JSStringCreateWithUTF8CString([propertyName UTF8String]);
			JSValueRef	valueJS = JSObjectGetProperty(ctx, object, propertyNameJS, NULL);
			JSStringRelease(propertyNameJS);
//			JSObjectRef objectProperty2 = JSValueToObject(ctx, valueJS, NULL);

//			NSLog(@"%c %@ %x %x", encoding, propertyName, valueJS, objectProperty2);
			if (encoding == '{')
			{
				if (JSValueIsObject(ctx, valueJS))
				{
					JSObjectRef objectProperty = JSValueToObject(ctx, valueJS, NULL);
					int numParsed = [self structureFromJSObjectRef:objectProperty inContext:ctx inParentJSValueRef:NULL fromCString:c fromStorage:ptr];
					c += numParsed;
				}
				else	return	0;
			}
			else
			{
				// Align 
				[JSCocoaFFIArgument alignPtr:ptr accordingToEncoding:encoding];
				// Get value
				[JSCocoaFFIArgument fromJSValueRef:valueJS inContext:ctx withTypeEncoding:encoding withStructureTypeEncoding:nil fromStorage:*ptr];
				// Advance ptr
				[JSCocoaFFIArgument advancePtr:ptr accordingToEncoding:encoding];
			}
			
		}
	}
	return	c-c0-1;
}



#pragma mark Encoding size, alignment, FFI

+ (int)sizeOfTypeEncoding:(char)encoding
{
	switch (encoding)
	{
		case	_C_ID:		return	sizeof(id);
		case	_C_CLASS:	return	sizeof(Class);
		case	_C_SEL:		return	sizeof(SEL);
		case	_C_CHR:		return	sizeof(char);
		case	_C_UCHR:	return	sizeof(unsigned char);
		case	_C_SHT:		return	sizeof(short);
		case	_C_USHT:	return	sizeof(unsigned short);
		case	_C_INT:		return	sizeof(int);
		case	_C_UINT:	return	sizeof(unsigned int);
		case	_C_LNG:		return	sizeof(long);
		case	_C_ULNG:	return	sizeof(unsigned long);
		case	_C_LNG_LNG:	return	sizeof(long long);
		case	_C_ULNG_LNG:return	sizeof(unsigned long long);
		case	_C_FLT:		return	sizeof(float);
		case	_C_DBL:		return	sizeof(double);
		case	_C_BOOL:	return	sizeof(BOOL);
		case	_C_VOID:	return	sizeof(void);
		case	_C_PTR:		return	sizeof(void*);
		case	_C_CHARPTR:	return	sizeof(char*);
	}
	return	-1;
}

/*

	__alignOf__ returns 8 for double, but its struct align is 4

	use dummy structures to get struct alignment, each having a byte as first element
*/
typedef	struct { char a; id b;			} struct_C_ID;
typedef	struct { char a; char b;		} struct_C_CHR;
typedef	struct { char a; short b;		} struct_C_SHT;
typedef	struct { char a; int b;			} struct_C_INT;
typedef	struct { char a; long b;		} struct_C_LNG;
typedef	struct { char a; long long b;	} struct_C_LNG_LNG;
typedef	struct { char a; float b;		} struct_C_FLT;
typedef	struct { char a; double b;		} struct_C_DBL;
typedef	struct { char a; BOOL b;		} struct_C_BOOL;

+ (int)alignmentOfTypeEncoding:(char)encoding
{
	switch (encoding)
	{
		case	_C_ID:		return	offsetof(struct_C_ID, b);
		case	_C_CLASS:	return	offsetof(struct_C_ID, b);
		case	_C_SEL:		return	offsetof(struct_C_ID, b);
		case	_C_CHR:		return	offsetof(struct_C_CHR, b);
		case	_C_UCHR:	return	offsetof(struct_C_CHR, b);
		case	_C_SHT:		return	offsetof(struct_C_SHT, b);
		case	_C_USHT:	return	offsetof(struct_C_SHT, b);
		case	_C_INT:		return	offsetof(struct_C_INT, b);
		case	_C_UINT:	return	offsetof(struct_C_INT, b);
		case	_C_LNG:		return	offsetof(struct_C_LNG, b);
		case	_C_ULNG:	return	offsetof(struct_C_LNG, b);
		case	_C_LNG_LNG:	return	offsetof(struct_C_LNG_LNG, b);
		case	_C_ULNG_LNG:return	offsetof(struct_C_LNG_LNG, b);
		case	_C_FLT:		return	offsetof(struct_C_FLT, b);
		case	_C_DBL:		return	offsetof(struct_C_DBL, b);
		case	_C_BOOL:	return	offsetof(struct_C_BOOL, b);
		case	_C_PTR:		return	offsetof(struct_C_ID, b);
		case	_C_CHARPTR:	return	offsetof(struct_C_ID, b);
	}
	return	-1;
}


+ (ffi_type*)ffi_typeForTypeEncoding:(char)encoding
{
	switch (encoding)
	{
		case	_C_ID:
		case	_C_CLASS:
		case	_C_SEL:
		case	_C_PTR:		
		case	_C_CHARPTR:		return	&ffi_type_pointer;
						
		case	_C_CHR:			return	&ffi_type_sint8;
		case	_C_UCHR:		return	&ffi_type_uint8;
		case	_C_SHT:			return	&ffi_type_sint16;
		case	_C_USHT:		return	&ffi_type_uint16;
		case	_C_INT:
		case	_C_LNG:			return	&ffi_type_sint32;
		case	_C_UINT:
		case	_C_ULNG:		return	&ffi_type_uint32;
		case	_C_LNG_LNG:		return	&ffi_type_sint64;
		case	_C_ULNG_LNG:	return	&ffi_type_uint64;
		case	_C_FLT:			return	&ffi_type_float;
		case	_C_DBL:			return	&ffi_type_double;
		case	_C_BOOL:		return	&ffi_type_sint8;
		case	_C_VOID:		return	&ffi_type_void;
	}
	return	NULL;
}

/*
	From
		{_NSRect={_NSPoint=ff}{_NSSize=ff}}
		
	Return
		{_NSRect="origin"{_NSPoint="x"f"y"f}"size"{_NSSize="width"f"height"f}}

*/

#pragma mark Structure encoding, size

+ (NSString*)structureNameFromStructureTypeEncoding:(NSString*)encoding
{
	// Extract structure name
	// skip '{'
	char*	c = (char*)[encoding UTF8String]+1;
	// skip '_' if it's there
	if (*c == '_')	c++;
	char*	c2 = c;
	while (*c2 && *c2 != '=') c2++;
	return [[[NSString alloc] initWithBytes:c length:(c2-c) encoding:NSASCIIStringEncoding] autorelease];
}

+ (NSMutableArray*)encodingsFromStructureTypeEncoding:(NSString*)encoding
{
	return	nil;
}

+ (NSString*)structureFullTypeEncodingFromStructureTypeEncoding:(NSString*)encoding
{
	id structureName = [JSCocoaFFIArgument structureNameFromStructureTypeEncoding:encoding];
	return	[self structureFullTypeEncodingFromStructureName:structureName];
}

+ (NSString*)structureFullTypeEncodingFromStructureName:(NSString*)structureName
{
	// Fetch structure type encoding from BridgeSupport
//	id xml = [[BridgeSupportController sharedController] query:structureName withType:@"struct"];
	id xml = [[BridgeSupportController sharedController] queryName:structureName type:@"struct"];

	if (xml == nil)
	{
		NSLog(@"No structure encoding found for %@", structureName);
		return	nil;
	}
	id xmlDocument = [[NSXMLDocument alloc] initWithXMLString:xml options:0 error:nil];
	if (!xmlDocument)	return	NO;
	id rootElement = [xmlDocument rootElement];
	id type = [[rootElement attributeForName:@"type"] stringValue];
	[xmlDocument release];
	return	type;
}


+ (NSArray*)typeEncodingsFromStructureTypeEncoding:(NSString*)structureTypeEncoding
{
	return [self typeEncodingsFromStructureTypeEncoding:structureTypeEncoding parsedCount:nil];
}


+ (NSArray*)typeEncodingsFromStructureTypeEncoding:(NSString*)structureTypeEncoding parsedCount:(int*)count
{
	id types = [[[NSMutableArray alloc] init] autorelease];
	char* c = (char*)[structureTypeEncoding UTF8String];
	char* c0 = c;
	int	openedBracesCount = 0;
	int closedBracesCount = 0;
	for (;*c; c++)
	{
		if (*c == '{')
		{
			openedBracesCount++;
			while (*c && *c != '=') c++;
			if (!*c)	continue;
		}
		if (*c == '}')
		{
			closedBracesCount++;
			continue;
		}
		if (*c == '=')	continue;
	
		if (c0 != c && closedBracesCount == openedBracesCount)	break;

		[types addObject:[NSString stringWithFormat:@"%c", *c]];

		// Special case for pointers
		if (*c == '^')
		{
			// Skip pointers to pointers (^^^)
			while (*c && *c == '^')	c++;
			
			// Skip type, special case for structure
			if (*c == '{')
			{
				int	openedBracesCount2 = 1;
				int closedBracesCount2 = 0;
				c++;
				for (; *c && closedBracesCount2 != openedBracesCount2; c++)
				{
					if (*c == '{')	openedBracesCount2++;
					if (*c == '}')	closedBracesCount2++;
				}
				c--;
			}
			else c++;
		}
		if (openedBracesCount == closedBracesCount)	
		{
			break;
		}
	}
	if (count) *count = c-c0;
	if (closedBracesCount != openedBracesCount)		return NSLog(@"Could not parse structure type encodings for %@", structureTypeEncoding), nil;
	return	types;
}


+ (int)sizeOfStructure:(NSString*)encoding
{
	id types = [self typeEncodingsFromStructureTypeEncoding:encoding];
	int computedSize = 0;
	void** ptr = (void**)&computedSize;
	for (id type in types)
	{
		char encoding = *(char*)[type UTF8String];
		// Align 
		[JSCocoaFFIArgument alignPtr:ptr accordingToEncoding:encoding];
		// Advance ptr
		[JSCocoaFFIArgument advancePtr:ptr accordingToEncoding:encoding];
	}
	return	computedSize;
}


#pragma mark Object boxing / unboxing

//
// Box
//
+ (BOOL)boxObject:(id)objcObject toJSValueRef:(JSValueRef*)value inContext:(JSContextRef)ctx
{
	// Return null if our pointer is null
	if (!objcObject)
	{
		*value = JSValueMakeNull(ctx);
		return	YES;
	}
	
	// Else, box the object
	JSObjectRef jsObject = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
	JSCocoaPrivateObject* private = JSObjectGetPrivate(jsObject);
	private.type = @"@";
	[private setObject:objcObject];
	*value = jsObject;
	return	YES;
}

//
// Unbox
//
+ (BOOL)unboxJSValueRef:(JSValueRef)value toObject:(id*)o inContext:(JSContextRef)ctx
{
	/*
		Boxing
		
		string	-> NSString
		null	-> nil	(no box)
		number	-> NSNumber
	*/
	
	// null
	if (!value || JSValueIsNull(ctx, value) || JSValueIsUndefined(ctx, value))
	{
		*(id*)o = nil;
		return	YES;
	}
	
	
	// string
	if (JSValueIsString(ctx, value))
	{
		JSStringRef resultStringJS = JSValueToStringCopy(ctx, value, NULL);
		NSString* resultString = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, resultStringJS);
		JSStringRelease(resultStringJS);
		[NSMakeCollectable(resultString) autorelease];
		*(id*)o = resultString;
		return	YES;
	}
	
	
	// number
	if (JSValueIsNumber(ctx, value))
	{
		double v = JSValueToNumber(ctx, value, NULL);
		// Integer
		if (fabs(round(v)-v) < 1e-6)
		{
			if (v < 0)	
			{
				*(id*)o = [NSNumber numberWithInt:(int)v];
//				NSLog(@"int %d", (int)v);
			}
			else		
			{
				*(id*)o = [NSNumber numberWithUnsignedInt:(unsigned int)v];
//				NSLog(@"UNSIGNED int %d", (unsigned int)v);
			}
		}
		// Double
		else
		{
			*(id*)o = [NSNumber numberWithDouble:v];
//			NSLog(@"double %f", v);
		}
		return	YES;
	}

	// number
	if (JSValueIsBoolean(ctx, value))
	{
		bool v = JSValueToBoolean(ctx, value);
		if (v)	*(id*)o = [NSNumber numberWithBool:YES];
		else	*(id*)o = nil;
		return	YES;
	}

	if (!JSValueIsObject(ctx, value))	
	{
		return	NO;
	}
	[JSCocoaController ensureJSValueIsObjectAfterInstanceAutocall:value inContext:ctx];
	
	JSObjectRef jsObject = JSValueToObject(ctx, value, NULL);
	JSCocoaPrivateObject* private = JSObjectGetPrivate(jsObject);
	// Pure js hashes and arrays should be converted to NSArray and NSDictionary. ##Later.
	if (!private)
	{
		// Use an anonymous function to test if object is Array or Object (hash)
		//	(can't use this.constructor==Array.prototype.constructor with JSEvaluateScript it doesn't take thisObject into account)
		JSStringRef scriptJS = JSStringCreateWithUTF8CString("return arguments[0].constructor == Array.prototype.constructor");
		JSObjectRef fn = JSObjectMakeFunction(ctx, NULL, 0, NULL, scriptJS, NULL, 1, NULL);
		JSValueRef result = JSObjectCallAsFunction(ctx, fn, NULL, 1, (JSValueRef*)&jsObject, NULL);
		JSStringRelease(scriptJS);

		BOOL isArray = JSValueToBoolean(ctx, result);
		
		if (isArray)	return	[self unboxJSArray:jsObject toObject:o inContext:ctx];
		else			return	[self unboxJSHash:jsObject toObject:o inContext:ctx];
	}
	// ## Hmmm ? CGColorRef is returned as a pointer but CALayer.foregroundColor asks an objc object (@)
	if ([private.type isEqualToString:@"rawPointer"])	*(id*)o = [private rawPointer];
	else												*(id*)o = [private object];
	return	YES;
}

//
// Convert ['a', 'b', 1.23] to an NSArray
//
+ (BOOL)unboxJSArray:(JSObjectRef)object toObject:(id*)o inContext:(JSContextRef)ctx
{
	// Get property count
	JSValueRef	exception = NULL;
	JSStringRef lengthJS = JSStringCreateWithUTF8CString("length");
	int length = JSValueToNumber(ctx, JSObjectGetProperty(ctx, object, lengthJS, NULL), &exception);
	JSStringRelease(lengthJS);
	if (exception)	return	NO;

	// Converted array
	id array = [NSMutableArray array];
	// Converted array property
	id value;
	int i;
	// Loop over all properties of the array and call our trusty unboxer. 
	// He might reenter that function to convert arrays inside that array.
	for (i=0; i<length; i++)
	{
		JSValueRef jsValue =  JSObjectGetPropertyAtIndex(ctx, object, i, &exception);
		if (exception)	return	NO;
		if (![self unboxJSValueRef:jsValue toObject:&value inContext:ctx])	return	NO;
		// Add converted value to array
		[array addObject:value];		
	}
	*o = array;
	return	YES;
}

//
// Convert { hello : 'world', count : 7 } to an NSDictionary
//
+ (BOOL)unboxJSHash:(JSObjectRef)object toObject:(id*)o inContext:(JSContextRef)ctx
{
	// Keys
	JSPropertyNameArrayRef names = JSObjectCopyPropertyNames(ctx, object);
	int length = JSPropertyNameArrayGetCount(names);

	// Converted hash
	id hash = [NSMutableDictionary dictionary];
	// Converted array property
	id value;

	JSValueRef	exception = NULL;
	int i;
	for (i=0; i<length; i++)
	{
		JSStringRef name	= JSPropertyNameArrayGetNameAtIndex(names, i);
		JSValueRef jsValue	= JSObjectGetProperty(ctx, object, name, &exception);
		if (exception)	return	NO;
		if (![self unboxJSValueRef:jsValue toObject:&value inContext:ctx])	return	NO;
		
		// Add converted value to hash
		id key				= (NSString*)JSStringCopyCFString(kCFAllocatorDefault, name);
		[hash setObject:value forKey:key];
		[NSMakeCollectable(key) release];
	}
	JSPropertyNameArrayRelease(names);
	*o = hash;
	return	YES;
}



	/*
		javascript:alert([].constructor==Array.prototype.constructor)		
	*/



@end
