//
//  ApplicationController.m
//  GC ObjC JSCocoa
//
//  Created by Patrick Geiller on 22/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ApplicationController.h"
#import "JSCocoa.h"

@implementation ApplicationController

- (void)applicationDidFinishLaunching:(id)notif
{
	NSLog(@"DONE");

	id c = [JSCocoaController sharedController];
	id mainJSFile = [NSString stringWithFormat:@"%@/Contents/Resources/main.js", [[NSBundle mainBundle] bundlePath]];
	[c evalJSFile:mainJSFile];


	[self performSelector:@selector(runJSTests:) withObject:nil afterDelay:0];
//	objc_assignIvar();
}

- (void)test
{
	NSLog(@"test");
}

int	runCount;
- (IBAction)runJSTests:(id)sender
{
	NSLog(@"RUN TESTS");
	id path = [[NSBundle mainBundle] bundlePath];
	path = [NSString stringWithFormat:@"%@/Contents/Resources/Tests", path];
//	NSLog(@"Run %d from %@", runCount, path);
	BOOL b = [[JSCocoaController sharedController] runTests:path];
	[JSCocoaController garbageCollect];
	if (!b)	{	NSLog(@"!!!!!!!!!!!FAIL %d from %@", runCount, path); return; }
	runCount++;
	NSLog(@">>>>Ran %d", runCount);
	[[NSGarbageCollector defaultCollector] collectExhaustively];
	objc_collect(OBJC_FULL_COLLECTION);
	objc_collect(OBJC_EXHAUSTIVE_COLLECTION);
	objc_collect(OBJC_WAIT_UNTIL_DONE);
NSLog(@"GC enabled=%d", [[NSGarbageCollector defaultCollector] isEnabled]);
}

- (IBAction)collect:(id)sender
{
	[[NSGarbageCollector defaultCollector] collectExhaustively];
	objc_collect(OBJC_FULL_COLLECTION);
	objc_collect(OBJC_EXHAUSTIVE_COLLECTION);
	objc_collect(OBJC_WAIT_UNTIL_DONE);
}

@end
