//
//  main.m
//  JSCoreAnimation
//
//  Created by Patrick Geiller on 19/09/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JSCocoaController.h"


int main(int argc, char *argv[])
{
	[[NSAutoreleasePool alloc] init];
	id c = [JSCocoaController sharedController];
	id mainJSFile = [NSString stringWithFormat:@"%@/Contents/Resources/main.js", [[NSBundle mainBundle] bundlePath]];
	[c evalJSFile:mainJSFile];
    return NSApplicationMain(argc,  (const char **) argv);
}


