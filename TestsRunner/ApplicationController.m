//
//  ApplicationController.m
//  TestsRunner
//
//  Created by Patrick Geiller on 17/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ApplicationController.h"
#import <JSCocoa/JSCocoa.h>

@implementation ApplicationController

- (void)awakeFromNib
{
//	NSLog(@"DEALLOC AUTORELEASEPOOL");
	[JSCocoaController deallocAutoreleasePool];
	[[NSAutoreleasePool alloc] init];

//	[[JSCocoaController sharedController] evalJSFile:[[NSBundle mainBundle] pathForResource:@"class" ofType:@"js"]];
/*	
	JSValueRef v;
	v = [[JSCocoaController sharedController] callJSFunctionNamed:@"test1" withArguments:[NSNumber numberWithInt:3], [NSNumber numberWithInt:5], @"hello!!", nil];
	NSLog(@">>RET=%@", [[JSCocoaController sharedController] formatJSException:v]);
	v = [[JSCocoaController sharedController] callJSFunctionNamed:@"test2" withArguments:nil];
	NSLog(@">>RET=%@", [[JSCocoaController sharedController] formatJSException:v]);
*/	
//	[[JSCocoaController sharedController] callJSFunctionNamed:@"test1" withArguments:self];
	
/*
	NSRect rect = { 10, 20, 30, 40 };
	NSRect rect1, rect2;
	NSDivideRect(rect, &rect1, &rect2, 5, 0);
	float* r;
	r = &rect;	NSLog(@"r=%f, %f, %f, %f", r[0], r[1], r[2], r[3]);
	r = &rect1;	NSLog(@"r1=%f, %f, %f, %f", r[0], r[1], r[2], r[3]);
	r = &rect2;	NSLog(@"r2=%f, %f, %f, %f", r[0], r[1], r[2], r[3]);
*/	
	[self performSelector:@selector(runJSTests:) withObject:nil afterDelay:0];
}
int runCount = 0;
- (IBAction)runJSTests:(id)sender
{
	id path = [[NSBundle mainBundle] bundlePath];
	path = [NSString stringWithFormat:@"%@/Contents/Resources/Tests", path];
//	NSLog(@"Run %d from %@", runCount, path);
	BOOL b = [[JSCocoaController sharedController] runTests:path];
	[self garbageCollect:nil];
	if (!b)	{	NSLog(@"!!!!!!!!!!!FAIL %d from %@", runCount, path); return; }
	else	NSLog(@"All tests ran OK !");
//	NSLog(@"===========OK ! Ran %d from %@", runCount, path);
	runCount++;
}

- (IBAction)garbageCollect:(id)sender
{
	NSLog(@">>>>=>GO FOR GC");
	[JSCocoa logInstanceStats];
	[JSCocoa garbageCollect];
	NSLog(@">>>>=>DONE GC");
	[JSCocoa logInstanceStats];
}


- (IBAction)runSimpleTestFile:(id)sender
{
	id js = @"2+2";
	js = @"NSWorkspace.sharedWorkspace.activeApplication";

	js = @"var a = NSMakePoint(2, 3)";


	[JSCocoaController garbageCollect];
	JSValueRefAndContextRef v = [[JSCocoaController sharedController] evalJSString:js];
	[JSCocoaController garbageCollect];
	
	JSStringRef resultStringJS = JSValueToStringCopy(v.ctx, v.value, NULL);
	NSString* r = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, resultStringJS);
	JSStringRelease(resultStringJS);
	
	NSLog(@"res=%@", r);
	[r release];
}

- (IBAction)unlinkAllReferences:(id)sender
{
//	[JSCocoa logInstanceStats];
	[[JSCocoaController sharedController] unlinkAllReferences];
//	[self garbageCollect:nil];
//	[JSCocoa logInstanceStats];
}


@end
