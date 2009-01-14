//
//  JSCocoaFFIArgument.h
//  JSCocoa
//
//  Created by Patrick Geiller on 14/07/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#ifndef JSCocoa_iPhone
#import <Cocoa/Cocoa.h>
#import <JavascriptCore/JavascriptCore.h>
#define MACOSX
#include <ffi/ffi.h>
#endif
#ifdef	JSCocoa_iPhone
#import "iPhone/ffi.h"
#endif

@interface JSCocoaFFIArgument : NSObject {
	char		typeEncoding;
	NSString*	structureTypeEncoding;

	void*		ptr;

	BOOL		isReturnValue;
	ffi_type	structureType;
	
	id			customData;
	BOOL		ownsStorage;
}

- (void)setTypeEncoding:(char)encoding;
- (void)setTypeEncoding:(char)encoding withCustomStorage:(void*)storagePtr;
- (void)setStructureTypeEncoding:(NSString*)encoding;
- (void)setStructureTypeEncoding:(NSString*)encoding withCustomStorage:(void*)storagePtr;

+ (int)sizeOfTypeEncoding:(char)encoding;
+ (int)alignmentOfTypeEncoding:(char)encoding;

+ (ffi_type*)ffi_typeForTypeEncoding:(char)encoding;

+ (int)sizeOfStructure:(NSString*)encoding;


+ (NSArray*)typeEncodingsFromStructureTypeEncoding:(NSString*)structureTypeEncoding;
+ (NSArray*)typeEncodingsFromStructureTypeEncoding:(NSString*)structureTypeEncoding parsedCount:(int*)count;


+ (NSString*)structureNameFromStructureTypeEncoding:(NSString*)structureTypeEncoding;
+ (NSString*)structureFullTypeEncodingFromStructureTypeEncoding:(NSString*)structureTypeEncoding;
+ (NSString*)structureFullTypeEncodingFromStructureName:(NSString*)structureName;

+ (BOOL)fromJSValueRef:(JSValueRef)value inContext:(JSContextRef)ctx withTypeEncoding:(char)typeEncoding withStructureTypeEncoding:(NSString*)structureTypeEncoding fromStorage:(void*)ptr;

+ (BOOL)toJSValueRef:(JSValueRef*)value inContext:(JSContextRef)ctx withTypeEncoding:(char)typeEncoding withStructureTypeEncoding:(NSString*)structureTypeEncoding fromStorage:(void*)ptr;

+ (int)structureToJSValueRef:(JSValueRef*)value inContext:(JSContextRef)ctx fromCString:(char*)c fromStorage:(void**)storage;
+ (int)structureToJSValueRef:(JSValueRef*)value inContext:(JSContextRef)ctx fromCString:(char*)c fromStorage:(void**)ptr initialValues:(JSValueRef*)initialValues initialValueCount:(int)initialValueCount convertedValueCount:(int*)convertedValueCount;
+ (int)structureFromJSObjectRef:(JSObjectRef)value inContext:(JSContextRef)ctx inParentJSValueRef:(JSValueRef)parentValue fromCString:(char*)c fromStorage:(void**)ptr;

+ (void)alignPtr:(void**)ptr accordingToEncoding:(char)encoding;
+ (void)advancePtr:(void**)ptr accordingToEncoding:(char)encoding;


- (void*)allocateStorage;
- (void**)storage;
- (char)typeEncoding;
- (NSString*)structureTypeEncoding;

- (void)setIsReturnValue:(BOOL)v;
//- (void)setCustomData:(id)data;

- (BOOL)fromJSValueRef:(JSValueRef)value inContext:(JSContextRef)ctx;
- (BOOL)toJSValueRef:(JSValueRef*)value inContext:(JSContextRef)ctx;


+ (BOOL)boxObject:(id)o toJSValueRef:(JSValueRef*)value inContext:(JSContextRef)ctx;
+ (BOOL)unboxJSValueRef:(JSValueRef)value toObject:(id*)o inContext:(JSContextRef)ctx;
+ (BOOL)unboxJSArray:(JSObjectRef)value toObject:(id*)o inContext:(JSContextRef)ctx;
+ (BOOL)unboxJSHash:(JSObjectRef)value toObject:(id*)o inContext:(JSContextRef)ctx;


- (ffi_type*)ffi_type;

@end
