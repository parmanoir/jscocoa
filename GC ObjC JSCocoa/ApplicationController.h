//
//  ApplicationController.h
//  GC ObjC JSCocoa
//
//  Created by Patrick Geiller on 22/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ApplicationController : NSObject {

}

- (IBAction)runJSTests:(id)sender;
- (IBAction)collect:(id)sender;
- (IBAction)dumpMemory:(id)sender;

@end
