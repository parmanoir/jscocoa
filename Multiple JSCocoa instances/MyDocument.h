//
//  MyDocument.h
//  Multiple JSCocoa instances
//
//  Created by Patrick Geiller on 11/01/09.
//  Copyright __MyCompanyName__ 2009 . All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "JSCocoa.h"

@interface MyDocument : NSDocument
{
	JSCocoa*	jsc;
	
	IBOutlet	id textField1;
	IBOutlet	id textField2;
	IBOutlet	id textField3;
	IBOutlet	id textField4;
}

- (IBAction)clicked:(id)sender;

@end
