//
//  JSCocoaHelper.m
//  JSCocoa
//
//  Created by Patrick Geiller on 18/09/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "JSCocoaHelper.h"


@implementation JSCocoaHelper

/*

	List of registered classes
	http://developer.apple.com/documentation/Cocoa/Reference/ObjCRuntimeRef/Reference/reference.html#//apple_ref/c/func/objc_getClassList

*/
+ (NSString*)classList
{
	id list = [NSMutableArray array];

	int numClasses;
	Class * classes = NULL;

	classes = NULL;
	numClasses = objc_getClassList(NULL, 0);

	if (numClasses > 0 )
	{
		classes = malloc(sizeof(Class) * numClasses);
		numClasses = objc_getClassList(classes, numClasses);
		
		int i;
		for (i=0; i<numClasses; i++) 
		{
			Class c = classes[i];
			id str;
			if (!class_respondsToSelector(c, @selector(superclass)))	
			{
				str = [NSString stringWithFormat:@"%s", class_getName(c)];
			}
			else
			{
				const char* className = (const char*)class_getName([c superclass]);				
				str = [NSString stringWithFormat:@"%s %s", class_getName(c), (!className || strcmp(className, "nil")) == 0 ? "" : className];
			}
			[list addObject:str];
		}
		free(classes);
	}
	return	[list componentsJoinedByString:@"\n"];
}

@end
