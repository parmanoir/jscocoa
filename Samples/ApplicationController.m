//
//  ApplicationController.m
//  Samples
//
//  Created by Patrick Geiller on 01/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ApplicationController.h"


@implementation ApplicationController

- (void)awakeFromNib
{
	jsc = [JSCocoa new];
//	[jsc 



/*
	id defaults = [NSUserDefaults standardUserDefaults];

//	NSLog(@"===%d", [defaults integerForKey:@"AppleAntiAliasingThreshold"]);



	[defaults setInteger:2 forKey:@"AppleAntiAliasingThreshold"];
	[defaults setInteger:2 forKey:@"AppleScreenAdvanceSizeThreshold"];
	[defaults setInteger:2 forKey:@"AppleSmoothFontsSizeThreshold"];
	
	[defaults synchronize];
*/

//	id path = [NSString stringWithFormat:@"%@document.js", [[NSBundle mainBundle] bundlePath]];
	id path = [[NSBundle mainBundle] pathForResource:@"document" ofType:@"js"];
	NSLog(@"path=%@", path);
	
//	canLoad = NO;
	BOOL evaled = [jsc evalJSFile:path];

}

@end
