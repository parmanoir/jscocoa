//
//  NSObject+WebScripting.m
//  Chocolate
//
//  Created by Fabien Franzen on 02-09-09.
//  Copyright 2009 Atelier Fabien. All rights reserved.
//

#import "NSObject+WebScripting.h"
#import <WebKit/WebKit.h>

@implementation NSObject (WebScripting)

+ (id)JSProxyFrom:(id)object {
    static SEL jsProxySelector;
    if (!jsProxySelector) jsProxySelector = @selector(JSProxy);
    if ([object respondsToSelector:jsProxySelector]) {
        return [object performSelector:jsProxySelector];
    } else {
        return object;
    }
}

- (id)defaultWebScriptProxy {
    return self;
}

- (void)setWebScriptValue:(id)value forKeyPath:(NSString *)keyPath {
    if ([value isKindOfClass:[WebScriptObject class]]) {
        NSArray *arrayValue = [[self class] arrayFromJavaScriptArray:value];
        if (arrayValue) {
            [self setValue:arrayValue forKeyPath:keyPath];
        } else {
            [self setValue:value forKeyPath:keyPath];
        }
    } else {
        [self setValue:value forKeyPath:keyPath];
    }
}

- (id)webScriptValueForKeyPath:(NSString *)keyPath {
    return [self valueForKeyPath:keyPath];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector {
    return NO;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name {
    return NO;
}

- (id)invokeUndefinedMethodFromWebScript:(NSString *)name withArguments:(NSArray *)args {
    id proxy = [self defaultWebScriptProxy];
    
    if ([name isEqualToString:@"toString"]) return [proxy description];
    if ([args count] == 0) return [proxy valueForKey:name];
        
    NSLog(@"Undefined WebScript Method Call: %@ - args: %@", name, args);
    return nil;
}

- (id)invokeDefaultMethodWithArguments:(NSArray *)args {
    id proxy = [self defaultWebScriptProxy];
    
    @try {
        if ([args count] > 0 && [[args objectAtIndex:0] isKindOfClass:[NSString class]]) {
            if ([args count] == 2) {
                NSString *keyPath = [args objectAtIndex:0];
                id value = [args objectAtIndex:1];
                [proxy setWebScriptValue:value forKeyPath:keyPath];
                return nil;
            } else if ([args count] == 1) {
                return [proxy webScriptValueForKeyPath:[args objectAtIndex:0]];
            }
        } else {
            return [proxy description];
        }
    } @catch(NSException *e) {
        NSLog(@"An exception occurred: %@", e);
	}
    return nil;
}

+ (NSArray *)arrayFromJavaScriptArray:(WebScriptObject *)javaScriptArray {
	@try {
		id lengthObj = [javaScriptArray valueForKey:@"length"];
		if(![lengthObj respondsToSelector:@selector(unsignedIntValue)]) return nil;
		
        NSUInteger length = [lengthObj unsignedIntValue];
		NSMutableArray *result = [NSMutableArray arrayWithCapacity:length];
		for (NSUInteger i = 0; i < length; ++i) {
			id item = [javaScriptArray webScriptValueAtIndex:i];
			if (item) [result addObject:item];
		}
		return result;
	} @catch(NSException *e) {
		// do nothing
	}
	return nil;
}

@end
