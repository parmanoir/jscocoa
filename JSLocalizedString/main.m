//
//  main.m
//  JSLocalizedString
//
//  Created by Patrick Geiller on 18/02/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JSCocoa.h"

int main(int argc, char *argv[])
{
	[[NSAutoreleasePool alloc] init];
	id c = [JSCocoaController sharedController];
	
	id path = [[NSBundle mainBundle] pathForResource:@"strings" ofType:@"js"];
//	NSLog(@"%@", path);
	[c evalJSFile:path];
    return NSApplicationMain(argc,  (const char **) argv);
}
