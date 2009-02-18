//
//  ApplicationController.h
//  JSLocalizedString
//
//  Created by Patrick Geiller on 18/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ApplicationController : NSObject {

	int	bookCount;
	IBOutlet id label;

}

- (IBAction)add:(id)sender;
- (IBAction)remove:(id)sender;
- (IBAction)openInternational:(id)sender;

@end
