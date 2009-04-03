//
//  ApplicationController.m
//  JSCocoaSandbox
//
//  Created by Patrick Geiller on 02/11/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "ApplicationController.h"
#import "NSLogConsole.h"


@implementation ApplicationController


- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	// Start console
	[NSLogConsole sharedConsole];

	[[NSView alloc] retain];

NSLog(@"1");

	// Create 'refresh' menu item
	id item = [[NSMenuItem alloc] initWithTitle:@"Refresh" action:@selector(refreshJSCocoa:) keyEquivalent:@"r"];
	id menu = [[NSApplication sharedApplication] mainMenu];
	menu = [[menu itemAtIndex:0] submenu];
	// Insert separator
	[menu insertItem:[NSMenuItem separatorItem] atIndex:[menu numberOfItems]-2];
	// Insert refresh
	[menu insertItem:item atIndex:[menu numberOfItems]-2];
	
	// Create 'view source' menu item
	
	TODO
	

	jsCocoaController = [JSCocoaController sharedController];
	// Load class construction kit
	id classJSFile = [NSString stringWithFormat:@"%@/Contents/Resources/class.js", [[NSBundle mainBundle] bundlePath]];
	[jsCocoaController evalJSFile:classJSFile];

	// Check argument count
	id args = [[NSProcessInfo processInfo] arguments];
	if ([args count] < 2)	
	{
		NSLog(@"JSCocoaSandbox : no file to launch — launch with JSCocoaLauncher");
		return;
	}
	id mainJSFile = [args objectAtIndex:[args count]-1];
//	mainJSFile = @"/Users/mini/Software Inexdo/JSCocoa/test.jscocoa";
	id pathParts = [mainJSFile pathComponents];
	// Update console name
	id title = [pathParts objectAtIndex:[pathParts count]-1];
	[[NSLogConsole sharedConsole] setWindowTitle:title];
	
	// Load file
	[jsCocoaController evalJSFile:mainJSFile];

	[NSApp activateIgnoringOtherApps:YES];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	[jsCocoaController release];
}

- (void)refreshJSCocoa:(id)notif
{
	NSLog(@"REFRESH");
	id args = [[NSProcessInfo processInfo] arguments];
	id path = [args objectAtIndex:[args count]-1];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:path]]; 
//	[NSApp terminate:nil];
}


@end
