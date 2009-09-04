//
//  ApplicationController.h
//  TestsRunner
//
//  Created by Patrick Geiller on 17/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ApplicationController : NSObject {

	IBOutlet	id webViewUsedAsContextSource;

}

- (IBAction)runJSTests:(id)sender;
- (IBAction)garbageCollect:(id)sender;

- (IBAction)runSimpleTestFile:(id)sender;
- (IBAction)unlinkAllReferences:(id)sender;

- (id)testDelegate;
- (int)dummyValue;


@end
