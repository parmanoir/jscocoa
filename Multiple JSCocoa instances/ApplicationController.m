//
//  ApplicationController.m
//  Multiple JSCocoa instances
//
//  Created by Patrick Geiller on 22/01/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ApplicationController.h"


@implementation ApplicationController


id classController = nil;

//- (void)applicationDidFinishLaunching:(id)notif
- (void)awakeFromNib
{
	classController = [[JSCocoa alloc] init];

	id path = [[NSBundle mainBundle] pathForResource:@"classCode" ofType:@"js"];
	[classController evalJSFile:path];
}

@end
