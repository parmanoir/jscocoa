//
//  WebCocoaAppDelegate.m
//  WebCocoa
//
//  Created by Patrick Geiller on 09/07/10.
//  Copyright 2010 Inexdo. All rights reserved.
//

#import "WebCocoaAppDelegate.h"

@implementation WebCocoaAppDelegate


@synthesize window;
@synthesize webview;
@synthesize jscocoa;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	NSLog(@"%@", webview);
	
	[webview setMainFrameURL:[[NSBundle mainBundle] pathForResource:@"WebCocoa.html" ofType:@""]];
	JSGlobalContextRef ctx = [[webview mainFrame] globalContext];
	jscocoa = [[JSCocoa alloc] initWithGlobalContext:ctx];
	[jscocoa setObject:self withName:@"myself"];
	
	NSLog(@"the page should list all classes and corresponding methods, derivation tree, etc. Also, searchable.");
	Ideally, integrate the editor into WebCocoa, and launch the debugger from there.
}
#pragma mark WebFrameLoadDelegate Methods

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame {
//	NSLog(@"didClearWindowObject:");

}

#pragma mark -

@end
