//
//  ApplicationController.h
//  TestsRunner
//
//  Created by Patrick Geiller on 17/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JSCocoa.h"


#define JSRESULTNUMBER (int)JSValueToNumber([jsc ctx], ret?ret:JSValueMakeUndefined([jsc ctx]), NULL)
	

@interface ApplicationController : NSObject <NSApplicationDelegate> {

	IBOutlet	id webViewUsedAsContextSource;
	IBOutlet	id window;
	IBOutlet	id textField;
	
	IBOutlet	NSTextField* evalText;
	IBOutlet	NSTextField* evalResult;
	
	JSCocoa* jsc2;
	id topObjects;
	
	NSError*	testNSError;
	
	BOOL		runningContinuously;
	// If we cycle context each time, we can test bindings each time.
	BOOL		cyclingContext;

}
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (void)applicationWillTerminate:(NSNotification *)notification;

- (IBAction)runJSTests:(id)sender;
- (IBAction)runJSTestsContinuously:(id)sender;
- (IBAction)stopContinuousJSTestsRun:(id)sender;
- (IBAction)garbageCollect:(id)sender;
- (IBAction)logInstanceStats:(id)sender;
- (IBAction)logBoxedObjects:(id)sender;
- (void)log:(NSString*)message;

- (IBAction)runSimpleTestFile:(id)sender;
- (IBAction)unlinkAllReferences:(id)sender;

- (IBAction)eval:(id)sender;

- (id)testDelegate;
- (int)dummyValue;
- (id)testCallAPI;
- (void)incorrectlySetJSValue:(JSValueRef)jsvalue;
- (void)setJSValue:(JSValueRefAndContextRef)vc;
- (JSValueRefAndContextRef)jsValue;

- (NSError*)testNSError;

- (void)disposeClass:(NSString*)className;
- (void)disposeShadowBindingsClasses;

- (void)dumpEncodings;

@end

@interface NSErrorTest : NSObject
- (BOOL)someMethodReturningAnError:(NSError**)error;
@end