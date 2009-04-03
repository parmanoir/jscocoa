//
//  main.m
//  JSCocoaLauncher
//
//  Created by Patrick Geiller on 01/04/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JSCocoa.h"

int main(int argc, char *argv[])
{
	[JSCocoa allocAutoreleasePool];
	[NSAutoreleasePool new];
	id jsc = [JSCocoa sharedController];
	[jsc evalJSFile:[[NSBundle mainBundle] pathForResource:@"launcher" ofType:@"js"]];

    return NSApplicationMain(argc,  (const char **) argv);
}
