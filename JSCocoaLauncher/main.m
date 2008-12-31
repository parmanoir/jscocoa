//
//  main.m
//  JSCocoaLauncher
//
//  Created by Patrick Geiller on 25/10/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JSCocoaController.h"

int main(int argc, char *argv[])
{
	[JSCocoaController allocAutoreleasePool];
	
	// Load class construction kit
	id classJSFile = [NSString stringWithFormat:@"%@/Contents/Resources/class.js", [[NSBundle mainBundle] bundlePath]];
	[[JSCocoaController sharedController] evalJSFile:classJSFile];

	// Load jscocoa list
	id mainJSFile = [NSString stringWithFormat:@"%@/Contents/Resources/JSCocoaLauncher.js", [[NSBundle mainBundle] bundlePath]];
	[[JSCocoaController sharedController] evalJSFile:mainJSFile];

    int r = NSApplicationMain(argc,  (const char **) argv);
	
	return	r;
}
