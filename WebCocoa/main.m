//
//  main.m
//  WebCocoa
//
//  Created by Patrick Geiller on 09/07/10.
//  Copyright 2010 Inexdo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
	id pool = [NSAutoreleasePool new];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"WebKitDeveloperExtras"];
	[pool release];
    return NSApplicationMain(argc,  (const char **) argv);
}
