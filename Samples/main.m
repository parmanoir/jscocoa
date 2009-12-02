//
//  main.m
//  Samples
//
//  Created by Patrick Geiller on 01/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
	id pool = [NSAutoreleasePool new];
	id dict = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:2], @"AppleAntiAliasingThreshold",
			[NSNumber numberWithInt:2], @"AppleScreenAdvanceSizeThreshold",
			[NSNumber numberWithInt:2], @"AppleSmoothFontsSizeThreshold",
			nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:dict];
	[pool release];


    return NSApplicationMain(argc, (const char **) argv);
}
