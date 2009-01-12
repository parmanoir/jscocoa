//
//  MyDocument.m
//  Multiple JSCocoa instances
//
//  Created by Patrick Geiller on 11/01/09.
//  Copyright __MyCompanyName__ 2009 . All rights reserved.
//

#import "MyDocument.h"

@implementation MyDocument

- (id)init
{
    self = [super init];
    if (self) {
    
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    
//		NSLog(@"new document");
    }
    return self;
}

- (void)dealloc
{
	NSLog(@"kill document");
	[jsc release];
	[super dealloc];
}

- (IBAction)clicked:(id)sender
{
	NSLog(@"clicked");
	NSLog(@"hasJSFunctionNamed('click')=%d", [jsc hasJSFunctionNamed:@"click"]);
	NSLog(@"hasJSFunctionNamed('clicked')=%d", [jsc hasJSFunctionNamed:@"clicked"]);	
	
	if ([jsc hasJSFunctionNamed:@"click"])	[jsc callJSFunctionNamed:@"click" withArguments:nil];
}


- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];

	// Start JSCocoa
	jsc = [[JSCocoa alloc] init];
	return;
		
	// Set our custom variables
	[jsc setObject:textField1 withName:@"field1"];
	[jsc setObject:textField2 withName:@"field2"];
	[jsc setObject:textField3 withName:@"field3"];
	[jsc setObject:textField4 withName:@"field4"];
	[jsc setObject:self withName:@"document"];
	
	// Load script
	id path = [[NSBundle mainBundle] pathForResource:@"documentCode" ofType:@"js"];
	[jsc evalJSFile:path];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that you set *outError when returning nil.

    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.

    // For applications targeted for Panther or earlier systems, you should use the deprecated API -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.

    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type.  If the given outError != NULL, ensure that you set *outError when returning NO.

    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead. 
    
    // For applications targeted for Panther or earlier systems, you should use the deprecated API -loadDataRepresentation:ofType. In this case you can also choose to override -readFromFile:ofType: or -loadFileWrapperRepresentation:ofType: instead.
    
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}

@end
