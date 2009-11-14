//
//  main.m
//  JSCocoa
//
//  Created by Patrick Geiller on 06/07/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JSCocoaController.h"

int main(int argc, char *argv[])
{
/*
#ifdef __LP64__
    printf("__LP64__!\n");
#endif
*/
	id pool = [[NSAutoreleasePool alloc] init];
	
	id c = [JSCocoaController new];
	id mainJSFile = [NSString stringWithFormat:@"%@/Contents/Resources/main.js", [[NSBundle mainBundle] bundlePath]];
	[c evalJSFile:mainJSFile];

    int r = NSApplicationMain(argc,  (const char **) argv);

	[pool release];

	return	r;
}
