//
//  main.m
//  iPhoneTest2
//
//  Created by Patrick Geiller on 12/10/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "JavascriptCore-dlsym.h"
#include "JSCocoaController.h"

int main(int argc, char *argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	// Fetch JS symbols
	[JSCocoaSymbolFetcher populateJavascriptCoreSymbols];

	// Load iPhone bridgeSupport
	[[BridgeSupportController sharedController] loadBridgeSupport:[NSString stringWithFormat:@"%@/iPhone.bridgeSupport", [[NSBundle mainBundle] bundlePath]]];
	// Load js class kit
	id c = [JSCocoaController sharedController];
	[c evalJSFile:[NSString stringWithFormat:@"%@/class.js", [[NSBundle mainBundle] bundlePath]]];
	// Load js main
	[c evalJSFile:[NSString stringWithFormat:@"%@/iPhoneMain.js", [[NSBundle mainBundle] bundlePath]]];
	

	// Start app
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
}
