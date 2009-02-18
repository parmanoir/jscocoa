//
//  ApplicationController.m
//  JSLocalizedString
//
//  Created by Patrick Geiller on 18/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ApplicationController.h"
#import "JSCocoa.h"


@implementation ApplicationController

- (id)init
{
	self = [super init];
	bookCount = 0;
	return	self;
}

- (void)awakeFromNib
{
	id str = JSLocalizedString(@"BookCount", [NSNumber numberWithInt:bookCount], nil);
	NSLog(@"init %d %@", bookCount, str);
	[label setStringValue:str];
}

- (IBAction)add:(id)sender
{
	bookCount++;
	id str = JSLocalizedString(@"BookCount", [NSNumber numberWithInt:bookCount], nil);
	NSLog(@"add %d %@", bookCount, str);
	[label setStringValue:str];
}
- (IBAction)remove:(id)sender
{
	if (bookCount > 0)	bookCount--;
	id str = JSLocalizedString(@"BookCount", [NSNumber numberWithInt:bookCount], nil);
	NSLog(@"remove %d", bookCount);
	[label setStringValue:str];
}

- (IBAction)openInternational:(id)sender
{
	system("open /System/Library/PreferencePanes/Localization.prefPane");
}


@end
