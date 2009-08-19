//
//  BurksPool.h
//  iPhoneTest2
//
//  Created by Patrick Geiller on 19/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "../JSCocoaController.h"


@interface BurksPool : NSObject {

}

+ (void)setJSFunctionHash:(id)jsFunctionHash;
+ (IMP)IMPforTypeEncodings:(NSArray*)encodings;
+ (BOOL)addMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext encodings:(id)encodings;

@end
