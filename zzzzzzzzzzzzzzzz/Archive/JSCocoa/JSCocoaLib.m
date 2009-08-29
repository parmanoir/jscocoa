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

	[JSCocoaFFIArgument fromJSValueRef:jsValue inContext:ctx typeEncoding:typeEncoding fullTypeEncoding:nil fromStorage:pointedValue];
	return	YES;
}


@end


//
// This is used to disassemble the resulting binary and check which objc_msgSend version is used.
//	otool -tV binary
//
//	objc_msgSend
//	objc_msgSend_fpret
//

@implementation JSCocoaObjCMsgSend

+ (float)addFloat:(float)a Float:(float)b
{
	float c = a+b;
//	NSLog(@"***** returning %f+%f=%f (0x%x+0x%x=0x%x)", a, b, c, *(unsigned long*)&a, *(unsigned long*)&b, *(unsigned long*)&c);
	NSLog(@"float %f", c);
	return a + b;
}

+ (double)addDouble:(double)a Double:(double)b
{
	double c = a+b;
	NSLog(@"double %f", c);
	return a + b;
}

+ (float)returnFloat
{
	return 1.2f;
}
+ (double)returnDouble
{
	return 3.4;
}

+ (CGPoint)returnPoint
{
	return CGPointMake(1, 2);
}
+ (CGRect)returnRect
{
	return CGRectMake(3, 4, 5, 6);
}


/*

http://richard.giliam.net/?p=20
inline int add2f(int a, int b) {
   int ret = 0;
   asm volatile (
      "add  %0, %1, %2     \n\t"
      : "=r"(ret)       // Output registers
      : "r"(a), "r"(b)  // Input registers
      : "r0", "r1"      // Clobber List
   );
   return ret;
}


*/

double absoluteInMemoryDouble = 3.2;
unsigned int absoluteInMemoryUInt = 1;
+ (void)checkObjCMsgSend
{

	float f1 = [self addFloat:3 Float:4];
	NSLog(@"f=%f", f1);
	double d1 = [self addDouble:3 Double:4];
	NSLog(@"d=%f", d1);

	return;

/*

	FMRS{cond} Rd, Sn
	The FMRS instruction transfers the contents of Sn into Rd.


	Store r0 in [sp]
	30004b84	e58d0010	str	r0, [sp, #16]

*/
/*

	__asm__("	ldr		r0, %0 		\n\t" : "=r"(addy));
	__asm__("	mov		%0, r0 		\n\t" : "=r"(savedR0));
	// Transfer s15 into r0
	__asm__("	fmrs	r0, s15		\n\t");
	__asm__("	mov		[%0], r0		\n\t" : "=r"(addy));
	__asm__("	mov		r0, %0		\n\t" : "=r"(savedR0));
*/
// load from 0x1c820
//0001c804	e59f3014	ldr	r3, [pc, #20]	; 0x1c820
// store 
//0001c808	e5823000	str	r3, [r2]

//	NSLog(@"got ARM float s15 %f", floatRes);
	
//	NEED LDR

//	absoluteInMemoryUInt += 0x12345678;
	
//	return;

//	NSLog(@"comment me out");
	
//	float returnedFloat = [self returnFloat];
//	float b2 = returnedFloat+0.5;
//	NSLog(@"%f", b2);
	
	
//	__asm__("mov	r0, r1");
	
	
/*
	
	___extendsfdf2vfp
___extendsfdf2vfp:
30002d64	ee070a90	fmsr	s15, r0
30002d68	eeb77ae7	fcvtds	d7, s15
30002d6c	ec510b17	fmrrd	r0, r1, d7

*/	
/*
	int x, y;
	double blah;
	blah = [self returnDouble];

	__asm__("	fmsr	s15, r0		\n\t");
	__asm__("	fcvtds	d7, s15		\n\t");
	__asm__("	fmrrd	r0, r1, d7	\n\t");
*/

//	__asm__("usat %0, #8, %1\n\t" : "=r"(y) : "r"(x));
//	__asm__("fstd %0, s15\n\t" : "=r"(blah));
//	__asm__("fsts s15, %1\n\t" : "=r"(y) : "r"(x));
//	__asm__("stfeqs");
//	__asm__("eazeazez %0, #8, %1\n\t" : "=r"(y) : "r"(x));
	
typedef	struct { char a; id b;			} struct_C_ID;
typedef	struct { char a; char b;		} struct_C_CHR;
typedef	struct { char a; short b;		} struct_C_SHT;
typedef	struct { char a; int b;			} struct_C_INT;
typedef	struct { char a; long b;		} struct_C_LNG;
typedef	struct { char a; long long b;	} struct_C_LNG_LNG;
typedef	struct { char a; float b;		} struct_C_FLT;
typedef	struct { char a; double b;		} struct_C_DBL;
typedef	struct { char a; BOOL b;		} struct_C_BOOL;

	NSLog(@"sizeof(id)=%d",		sizeof(id));
	NSLog(@"sizeof(char)=%d",	sizeof(char));
	NSLog(@"sizeof(short)=%d",	sizeof(short));
	NSLog(@"sizeof(int)=%d",	sizeof(int));
	NSLog(@"sizeof(long)=%d",	sizeof(long));
	NSLog(@"sizeof(float)=%d",	sizeof(float));
	NSLog(@"sizeof(double)=%d",	sizeof(double));
	NSLog(@"sizeof(BOOL)=%d",	sizeof(BOOL));
	
	NSLog(@"UISlider.value encoding=%s", [JSCocoa typeEncodingOfMethod:@"value" class:@"UISlider"]);

//	NSLog(@"float=%f", [self returnFloat]);
//	NSLog(@"double=%f", [self returnDouble]);
	id slider = [[UISlider alloc] init];
//	[slider setValue:0.6];
	NSLog(@"check dummy slider value");
	NSLog(@"dummy slider.value=%f", [slider value]);
	
	float d = [self addFloat:3 Float:4];
	NSLog(@"d=%f", d);
	float a, b, c;
	a = 4;
	b = 3;
	c = a+b;
	NSLog(@"hello");
	NSLog(@"%f", c);
	a = 5;
	b = 6;
	c = a*b;
	NSLog(@"%f", c);
	NSLog(@"hello");
	
//#pragma arm
	c = a*c;
	NSLog(@"%f", c);
//#pragma arm
	c = b*c;
	NSLog(@"%f", c);
	
	double da, db, dc;
	da = 3;
	db = 2;
	dc = da+db;
	NSLog(@"%f", dc);
	dc = da*db+absoluteInMemoryDouble;
	NSLog(@"%f", dc);
	
}

@end

/*
#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR

//
//	This file needs to be compiled with -mno-thumb in 'Additional Compiler Flags' in File Info (right click) > Build
//	-mno-thumb enables fpu register access.
//	
//	Done with ___extendsfdf2vfp when compiled.
//
//##LATER : if working, move to own file
@implementation JSCocoaIPhoneLibffiFix

+ (float)returnFloatFromRegistersAfterARMFFICall
{
	float		floatRes = -1;
//	unsigned int addy = (unsigned int)&floatRes;
	// Aligned ?
	void*		addy = malloc(sizeof(float));
	

	// ## what about the clobber list ? 
	__asm__("usat %0, #8, %1\n\t" : "=r"(addy) : "r"(addy) : "r0");

//	__asm__("	push	r0		\n\t"		);
//	__asm__("	push	{r1}		\n\t"		);
	__asm__("	mov		r0, %0 		\n\t" 		: "=r"(addy));
	__asm__("	fmrs	r1, s15		\n\t"		);
	__asm__("	str		r1, [r0]	\n\t"		);
//	__asm__("	pop		{r1}		\n\t"		);
//	__asm__("	pop		{r0}		\n\t"		);
	
	floatRes = *(float*)addy;
	NSLog(@"got ARM float s15 %f (%x)", floatRes, addy);
	

	return	floatRes;
}

+ (double)returnDoubleFromRegistersAfterARMFFICall
{
	double		doubleRes = -1;
//	unsigned int addy = (unsigned int)&doubleRes;
	void*		addy = malloc(sizeof(double));

	__asm__("	mov		r0, %0 		\n\t" 		: "=r"(addy) );
	__asm__("	fstd	d7, [r0]	\n\t"		);
	
	doubleRes = *(double*)addy;
	NSLog(@"got ARM double d7 %f (%x)", doubleRes, addy);

	return	doubleRes;
}


@end

#endif

*/
