//
//  ApplicationController.m
//  Samples
//
//  Created by Patrick Geiller on 01/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ApplicationController.h"

#import <execinfo.h>

@implementation ApplicationController

- (void)awakeFromNib
{
	jsc = [JSCocoa new];
//	[jsc 

/*
	Dl_info info;
	dladdr(dlsym(RTLD_DEFAULT, "backtrace"), &info);
	NSLog(@">>%s", info.dli_fname);


	NSLog(@"******%s***", [JSCocoa typeEncodingOfMethod:@"_setFrameCommon:display:stashSize:" class:@"NSWindow"]);
*/
/*

                                                  2 -[NSWindow _setFrameCommon:display:stashSize:]
                                                    2 -[NSWindow _oldPlaceWindow:]
                                                      2 -[NSWindow _setFrame:updateBorderViewSize:]


*/

/*
	id defaults = [NSUserDefaults standardUserDefaults];

//	NSLog(@"===%d", [defaults integerForKey:@"AppleAntiAliasingThreshold"]);



	[defaults setInteger:2 forKey:@"AppleAntiAliasingThreshold"];
	[defaults setInteger:2 forKey:@"AppleScreenAdvanceSizeThreshold"];
	[defaults setInteger:2 forKey:@"AppleSmoothFontsSizeThreshold"];
	
	[defaults synchronize];
*/
/*
	NSLog(@"%@", [NSThread callStackSymbols]);
	NSLog(@"========================");
	NSLog(@"%@", [NSThread callStackReturnAddresses]);
*/
//	id path = [NSString stringWithFormat:@"%@document.js", [[NSBundle mainBundle] bundlePath]];
	id path = [[NSBundle mainBundle] pathForResource:@"document" ofType:@"js"];
	NSLog(@"path=%@", path);
	
//	canLoad = NO;
	BOOL evaled = [jsc evalJSFile:path];

}

@end

