//
//  WebCocoaAppDelegate.h
//  WebCocoa
//
//  Created by Patrick Geiller on 09/07/10.
//  Copyright 2010 Inexdo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebView.h>
#import "JSCocoa.h"

@interface WebCocoaAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow*	window;

	WebView*	webview;
	JSCocoa*	jscocoa;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet WebView *webview;
@property (retain)			JSCocoa *jscocoa;

@end
