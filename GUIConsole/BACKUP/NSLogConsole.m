//
//  NSLogConsole.m
//  NSLogConsole
//
//  Created by Patrick Geiller on 16/08/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSLogConsole.h"
#import "JSCocoaController.h"


BOOL inited = NO;


void	NSLogPostLog(char* file, int line)
{
	if (!inited)	return;
	[[NSLogConsole sharedConsole] updateLogWithFile:file lineNumber:line];
}



@implementation NSLogConsole

@synthesize autoOpens;


+ (id)sharedConsole
{
	static id singleton = NULL;
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [self alloc];
			[singleton init];
		}
	}
	return singleton;
}


- (id)init
{
	id o		= [super init];
	autoOpens	= YES;
	logPath		= NULL;
//return	o;
	// Save stderr
	original_stderr = dup(STDERR_FILENO);

	inited = YES;

	logPath = [NSString stringWithFormat:@"%@%@.log.txt", NSTemporaryDirectory(), [[NSBundle mainBundle] bundleIdentifier]];
	[logPath retain];

	// Create the file — NSFileHandle doesn't do it !
	[@"" writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];

	fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
	if (!fileHandle)	NSLog(@"Opening log at %@ failed", logPath);
	[fileHandle retain];
	int fd = [fileHandle fileDescriptor];

	// Redirect stderr
	int err = dup2(fd, STDERR_FILENO);
	if (!err)	NSLog(@"Couldn't redirect stderr");

	fileOffset = 0;
	return	o;
}


- (void)dealloc
{
	[logPath release];
	[fileHandle release];
	[super dealloc];
}

- (void)open
{
/*
	if (!window)
	{
		if (![NSBundle loadNibNamed:@"NSLogConsole" owner:self])
		{
			NSLog(@"NSLogConsole.nib not loaded");
			return;
		}
		if ([window respondsToSelector:@selector(setBottomCornerRounded:)])
			[window setBottomCornerRounded:NO];
	}
	[window orderFront:self];
*/	
}
- (void)close
{
	[window orderOut:self];
}
- (BOOL)isOpen
{
	return	[window isVisible];
}

- (IBAction)clear:(id)sender
{
	[webView clear];
}
- (IBAction)searchChanged:(id)sender
{
	[webView search:[sender stringValue]];
}

- (void)setWebView:(id)view
{
	webView = view;
	[webView retain];
}

- (id)webView
{
	return	webView;
}


- (void)logData:(NSData*)data file:(char*)file lineNumber:(int)line
{
//	if (![window isVisible] && autoOpens)	[self open];

	id str = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
//	[[NSAlert alertWithMessageText:@"hello" defaultButton:@"Furthe" alternateButton:nil otherButton:nil informativeTextWithFormat:str] runModal];

	// Write back to original stderr
	write(original_stderr, [data bytes], [data length]);

	// Clear search
	[searchField setStringValue:@""];
	[webView search:@""];
	// Log string
	[webView logString:str file:file lineNumber:line];
	
	[str release];
}

- (void)updateLogWithFile:(char*)file lineNumber:(int)line
{
//	if (![window isVisible] && autoOpens)	[self open];
	// Open a new handle to read new data
	id f = [NSFileHandle fileHandleForReadingAtPath:logPath];
	if (!f)	NSLog(@"Opening log at %@ failed", logPath);

	// Get file length
	[f seekToEndOfFile];
	unsigned long long length = [f offsetInFile];

	// Read data
	[f seekToFileOffset:fileOffset];
	NSData* data = [f readDataToEndOfFile];
	[self logData:data file:file lineNumber:line];
	
	// We'll read from that offset next time
	fileOffset = length;
}


@end











@implementation NSLogConsoleView


- (void)dealloc
{
	[messageQueue release];
	[super dealloc];
}

- (BOOL)drawsBackground
{
	return	NO;
}

- (void)awakeFromNib
{
	messageQueue	= [[NSMutableArray alloc] init];
	webViewLoaded	= NO;

	// Frame load
	[self setFrameLoadDelegate:self];

	// Load html page
	id path = [[NSBundle mainBundle] pathForResource:@"NSLogConsole" ofType:@"html"];
	[[self mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];

	// Navigation notification
	[self setPolicyDelegate:self];
}

//
//	Javascript is available
//		Register our custom javascript object in the hosted page
//
- (void)webView:(WebView *)view windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject
{
	[windowScriptObject setValue:self forKey:@"NSLogConsoleView"];
}

//
// WebView has finished loading
//
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	webViewLoaded	= YES;

	// Flush message queue
	for (id o in messageQueue)
		[self logString:[o valueForKey:@"string"] file:(char*)[[o valueForKey:@"file"] UTF8String] lineNumber:[[o valueForKey:@"line"] intValue]];
	[messageQueue release];
	[[self windowScriptObject] setValue:self forKey:@"myVar"];
}

//
// Notify WebView of new message
//
- (void)logString:(NSString*)string file:(char*)file lineNumber:(int)line
{
	// Queue message if WebView has not finished loading
	if (!webViewLoaded)
	{
		id o = [NSDictionary dictionaryWithObjectsAndKeys:	[NSString stringWithString:string], @"string",
															[NSString stringWithUTF8String:file], @"file",
															[NSNumber numberWithInt:line], @"line",
															nil];
		[messageQueue addObject:o];
		return;
	}
	[[self windowScriptObject] callWebScriptMethod:@"log" withArguments:[NSArray arrayWithObjects:string, 
																			[NSString stringWithUTF8String:file], 
																			[NSNumber numberWithInt:line],
																			nil]];
}


//
// Open source file in XCode at correct line number
//
- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation
                                                           request:(NSURLRequest *)request
                                                             frame:(WebFrame *)frame
                                                  decisionListener:(id<WebPolicyDecisionListener>)listener
{
	// Get path, formed by AbsolutePathOnDisk(space)LineNumber
	NSString* pathAndLineNumber = [[request URL] path];
	
	// From end of string, skip to space before number
	char* s = (char*)[pathAndLineNumber UTF8String];
	char* s2 = s+strlen(s)-1;
	while (*s2 && *s2 != ' ' && s2 > s) s2--;
	if (*s2 != ' ')	return	NSLog(@"Did not find line number in %@", pathAndLineNumber);
	
	// Patch a zero to recover path
	*s2 = 0;
	
	// Get line number
	int line;
	BOOL foundLine = [[NSScanner scannerWithString:[NSString stringWithUTF8String:s2+1]] scanInt:&line];
	if (!foundLine)	return	NSLog(@"Did not parse line number in %@", pathAndLineNumber);

	// Get path
	NSString* path = [NSString stringWithUTF8String:s];
//	NSLog(@"opening line %d of _%@_", line, path);

	// Open in XCode
	id source = [NSString stringWithFormat:@"tell application \"Xcode\"									\n\
												set doc to open \"%@\"									\n\
												set selection to paragraph (%d) of contents of doc		\n\
											end tell", path, line];
	id script = [[NSAppleScript alloc] initWithSource:source];
	[script executeAndReturnError:nil];
	[script release];
}


- (void)clear
{
	[[self windowScriptObject] callWebScriptMethod:@"clear" withArguments:nil];
}

- (void)search:(NSString*)string
{
	[[self windowScriptObject] callWebScriptMethod:@"search" withArguments:[NSArray arrayWithObjects:string, nil]];
}


+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	return	NO;
}



//
// Hairy function below. WebView calls ApplicationController (written in JS)
//
- (void)evalJSCocoa:(NSString*)string
{
	id delegate = [[NSApplication sharedApplication] delegate];
	[[delegate inputScript] setStringValue:string];
	[delegate runScript:string];
}


//
//	Overlay Help
//
- (void)openHelp
{
	[[self windowScriptObject] callWebScriptMethod:@"openHelp" withArguments:nil];	
}
- (void)closeHelp
{
	[[self windowScriptObject] callWebScriptMethod:@"closeHelp" withArguments:nil];	
}
- (BOOL)isHelpOpen
{
	id result = [[self windowScriptObject] callWebScriptMethod:@"isHelpOpen" withArguments:nil];
	if (![result respondsToSelector:@selector(boolValue)])	return	NO;
	return [result boolValue];
}

//
// Command display
//
- (void)startCommand:(id)command
{
	[[self windowScriptObject] callWebScriptMethod:@"startCommand" withArguments:[NSArray arrayWithObjects:command, nil]];
}
- (void)endCommand
{
	/*id result = */[[self windowScriptObject] callWebScriptMethod:@"endCommand" withArguments:nil];
}


- (void)performFindPanelAction:(id)sender
{

	NSLog(@"iiiiiiiiiiiiiiii");
}


@end

