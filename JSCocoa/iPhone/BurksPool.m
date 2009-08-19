//
//  BurksPool.m
//  iPhoneTest2
//
//  Created by Patrick Geiller on 19/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "BurksPool.h"
#import "JSCocoaController.h"
#import "JSCocoaFFIArgument.h"
#import <objc/runtime.h>


static id IMPs = nil;

@implementation BurksPool


- (id)v_at_sel
{
	NSLog(@"Called on get ************** self=%@", self);
	return nil;
}

- (void)setValue:(id)i
{
	NSLog(@"Called on set ************** %@ self=%@", i, self);
}

//
// Flatten an encoding array to a string
//
+ (id)flattenEncoding:(id)encodings
{
	id fullEncodingArray = [NSMutableArray array];
	for (JSCocoaFFIArgument* arg in encodings)
	{
		if ([arg typeEncoding] == '{')	[fullEncodingArray addObject:[arg structureTypeEncoding]];
		else							[fullEncodingArray addObject:[NSString stringWithFormat:@"%c", [arg typeEncoding]]];
	}
	id fullEncoding = [fullEncodingArray componentsJoinedByString:@""];
	return	fullEncoding;
}

//
// Gather instance method implementations, removing ObjC indices (@8@0:4 -> @@:)
//
+ (void)gatherIMPs
{
	IMPs = [NSMutableDictionary new];
	unsigned int methodCount;
	Method* methods = class_copyMethodList([self class], &methodCount);
	for (int i=0; i<methodCount; i++)
	{
		Method m = methods[i];
		IMP imp = method_getImplementation(m);
		id encoding = [self flattenEncoding:[JSCocoaController parseObjCMethodEncoding:method_getTypeEncoding(m)]];
//		NSLog(@"(%d) sel=%s enc=%s ENC2=%@", i, method_getName(m), method_getTypeEncoding(m), encoding);
		[IMPs setObject:[NSNumber numberWithUnsignedLong:(long)imp] forKey:encoding];
	}
	free(methods);
}


+ (IMP)IMPforTypeEncodings:(NSArray*)encodings
{
	if (!IMPs)	[self gatherIMPs];
	
	id encoding = [self flattenEncoding:encodings];
	
	NSNumber* IMPnumber = [IMPs objectForKey:encoding];
//	NSLog(@"enc=%@*** IMP=%@", encoding, IMPnumber);
	if (IMPnumber)	return (IMP)[IMPnumber unsignedLongValue];
	return	nil;
}


@end
