//
//  ApplicationController.m
//  TestsRunner
//
//  Created by Patrick Geiller on 17/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ApplicationController.h"
#import "JSCocoa.h"
#import <WebKit/WebKit.h>

@implementation ApplicationController

JSCocoaController* jsc = nil;

//- (void)awakeFromNib
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	[JSCocoaController hazardReport];

	jsc = nil;
//	jsc = [JSCocoa new];
//	[jsc evalJSFile:[[NSBundle mainBundle] pathForResource:@"test" ofType:@"js"]];

	[[NSApplication sharedApplication] setDelegate:self];
	[self performSelector:@selector(runJSTests:) withObject:nil afterDelay:0];

	testNSError = nil;
	
//	NSLog(@"sizeof(int)=%d", sizeof(int));
//	NSLog(@"sizeof(long)=%d", sizeof(long));
//	NSLog(@"sizeof(CGFloat)=%d", sizeof(CGFloat));
	NSLog(@"*** Running %@ ***", [JSCocoa runningArchitecture]);

	cyclingContext = NO;
/*	
	id error = nil;
	id url = [NSURL fileURLWithPath:@"/non/existent"];
	BOOL b = [@"hello" writeToURL:url atomically:NO encoding:NSUTF8StringEncoding error:&error];
	NSLog(@"++++++++ %d %@", b, error);
*/
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	if (testNSError)	[testNSError release];

	[self disposeShadowBindingsClasses];

	if ([jsc retainCount] == 2)	NSLog(@"willTerminate %@ JSCocoa retainCount=%d (OK)", jsc, [jsc retainCount]);
	else						NSLog(@"willTerminate %@ JSCocoa retainCount=%d", jsc, [jsc retainCount]);

	// Check if JSCocoa can be released (retainCount got down to 1)
	// Won't work under ObjC GC
#ifndef __OBJC_GC__
	// Must be 2 with new release method
	if ([jsc retainCount] != 2)									NSLog(@"***Invalid JSCocoa retainCount***");
#endif
	[jsc release];
	
	id path = [NSString stringWithFormat:@"%@/Contents/Resources/Tests/! stock", [[NSBundle mainBundle] bundlePath]];
	id files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
	if ([files count])											NSLog(@"***warning, skipping tests in ./!stock***"), NSLog(@"%@", files);
#ifdef __OBJC_GC__
	if (![[NSGarbageCollector defaultCollector] isEnabled])		NSLog(@"***GC running but disabled***");
#endif	
}

- (void)cycleContext
{
	cyclingContext = YES;
	[self disposeShadowBindingsClasses];
	[jsc release];
	jsc = [JSCocoa new];
	[jsc evalJSFile:[[NSBundle mainBundle] pathForResource:@"test" ofType:@"js"]];
}


//
// Run unit tests + delegate tests
//
int runCount = 0;

- (IBAction)runJSTests:(id)sender
{
	[self cycleContext];

	[textField setStringValue:@"Running Tests ..."];

	// Clean up notifications registered by previously run tests
	[jsc callJSFunctionNamed:@"resetDelayedTests" withArguments:nil];

	//
	// Run js tests
	//
	runCount++;
	jsc.delegate = nil;
	id path = [[NSBundle mainBundle] bundlePath];
	path = [NSString stringWithFormat:@"%@/Contents/Resources/Tests", path];
//	NSLog(@"Run %d from %@", runCount, path);
	int testCount = [jsc runTests:path];
	BOOL b = !!testCount;
	[self garbageCollect:nil];

	//
	// Test delegate
	//
	id error = nil;
	error = [self testDelegate];
	if (error)
	{
		b = NO;
		path = error;
	}
	jsc.delegate = nil;
	
	//
	// Test api
	//
	[self testCallAPI];


	//
	// Test JSCocoa inited from a WebView
	//
	id webViewClass = objc_getClass("WebView");
	// Manually load WebKit if it's not yet loaded
	if (!webViewClass) 
	{
		[jsc loadFrameworkWithName:@"WebKit"];
		webViewClass = objc_getClass("WebView");
	}
	if (webViewClass && 1)
	{
//		NSLog(@"Testing initing from a WebView");
		// Load nib
		id nibPath	= [NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] bundlePath], @"/Contents/Resources/Tests/Resources/inited from WebView.nib"];
		id nibURL	= [NSURL fileURLWithPath:nibPath];
		id webViewNib = [[NSNib alloc] initWithContentsOfURL:nibURL];

		// Instantiate nib with ourselves as owner
		topObjects = nil;
		[webViewNib instantiateNibWithOwner:self topLevelObjects:&topObjects];
		[webViewNib release];
		[topObjects retain];
		[webViewUsedAsContextSource setFrameLoadDelegate:self];

		id pageURL	= [NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] resourcePath], @"/Tests/Resources/37 inited from webview.html"];
		[webViewUsedAsContextSource setMainFrameURL:pageURL];

		// Init JSCocoa from WebView's globalContext
		JSGlobalContextRef ctx = [[webViewUsedAsContextSource mainFrame] globalContext];
//		NSLog(@"WebView contextGroup=%x context=%x", JSContextGetGroup(ctx), ctx);
		jsc2 = [[JSCocoa alloc] initWithGlobalContext:ctx];
	}
	else
	{
		NSLog(@"WebKit not loaded - cannot test JSCocoa inited from a WebView");
	}


	if (!b)	
	{	
		id str = [NSString stringWithFormat:@"FAILED %@", path];
		[textField setStringValue:str];
		NSLog(@"!!!!!!!!!!!FAIL runCount %d in %@", runCount, path); 
		return; 
	}
	else	
	{
		int delayedTestCount = [jsc toInt:[jsc callJSFunctionNamed:@"delayedTestCount" withArguments:nil]];
		
		if (delayedTestCount)	
		{
			id str = [NSString stringWithFormat:@"All %d tests ran OK, %d delayed pending", testCount, delayedTestCount];
			NSLog(@"%@", str);
			[textField setStringValue:str];
		}
		else					
		{
			id str = [NSString stringWithFormat:@"All %d tests ran OK !", testCount];
			NSLog(@"%@", str);
			[textField setStringValue:str];
		}
	}
	
	//
	// Test autocall-less ObjJ
	//
	b = [jsc useAutoCall];
	[jsc setUseAutoCall:NO];

	id str = [jsc toString:[jsc evalJSString:@"[JSCocoa runningArchitecture]"]];
	[jsc setUseAutoCall:b];
	[jsc setUseJSLint:YES];
	if (![str isEqualToString:[JSCocoa runningArchitecture]])	NSLog(@"!!!!!!!!!!ObjJ syntax with autocall disabled failed");
	
/*	
	id class = objc_getClass([@"ファイナンス" UTF8String]);
	id o = [class new];
	NSLog(@"japanese class=%@", class);
	NSLog(@"japanese instance=%@", o);
	NSLog(@"japanese selector=%s", NSSelectorFromString(@"だけを追加する:"));
	
//	id r = [o performSelector:NSSelectorFromString(@"だけを追加する:") withObject:[NSNumber numberWithInt:7]];
	id r = [o performSelector:[@"だけを追加する:" UTF8String] withObject:[NSNumber numberWithInt:7]];
	NSLog(@"r=%@", r);
*/
}


- (IBAction)_runJSTestsContinuously:(id)sender
{
	[self runJSTests:nil];
	if (runningContinuously) [self performSelector:@selector(_runJSTestsContinuously:) withObject:nil afterDelay: 0.1];
}

- (IBAction)runJSTestsContinuously:(id)sender
{
	runningContinuously = YES;
	[self performSelector:@selector(_runJSTestsContinuously:) withObject:nil afterDelay: 0.1];
}
- (IBAction)stopContinuousJSTestsRun:(id)sender
{
	runningContinuously = NO;
}


//
// GC
//
- (IBAction)garbageCollect:(id)sender
{
	[jsc garbageCollect];
}

- (IBAction)logInstanceStats:(id)sender
{
	[JSCocoa logInstanceStats];
}

- (IBAction)logBoxedObjects:(id)sender
{
	[JSCocoa logBoxedObjects];
}

- (void)log:(NSString*)message
{
	NSLog(@"%@", message);
}


- (IBAction)runSimpleTestFile:(id)sender
{
	id js = @"2+2";
	js = @"NSWorkspace.sharedWorkspace.activeApplication";

	js = @"var a = NSMakePoint(2, 3)";
	[JSCocoaController garbageCollect];
	JSValueRef ret = [jsc evalJSString:js];
	[JSCocoaController garbageCollect];
	
	JSStringRef resultStringJS = JSValueToStringCopy([jsc ctx], ret, NULL);
	NSString* r = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, resultStringJS);
	JSStringRelease(resultStringJS);
	
	NSLog(@"res=%@", r);
	[r release];
}

- (IBAction)unlinkAllReferences:(id)sender
{
//	[JSCocoa logInstanceStats];
//	[[JSCocoaController sharedController] unlinkAllReferences];
	[jsc unlinkAllReferences];
//	[self garbageCollect:nil];
//	[JSCocoa logInstanceStats];
}



//
// Delegate testing
//
BOOL	hadError;

BOOL	canGet, canSet, didSet, canGetGlobal, canLoad, canEval;
id		object;
id		propertyName;
BOOL	equalsButtonCell, equalsBezelStyle;
id		functionName;
id		methodName;
BOOL	canCallC, canCallObjC;
id		pathtoJSFile;
id		customScript;
id		scriptToEval;
id		o;


JSValueRef	customValueGet, customValueSet, customValueCall, jsValue, ret, willReturn, customValueReturn, customValueGetGlobal;

- (id)testDelegate
{
	jsc.delegate = self;
	
	hadError	= NO;
	canCallC	= YES;
	canCallObjC	= YES;
	canSet		= YES;
	canGet		= YES;
	didSet		= YES;
	canGetGlobal= YES;
	canLoad		= YES;
	canEval		= YES;
	customValueGet		= NULL;
	customValueSet		= NULL;
	customValueCall		= NULL;
	customValueReturn	= NULL;
	customValueGetGlobal= NULL;
	
	// Test delegate without JSLint. If not, delegate get test will choke on lint(source.split('\n'))
	BOOL useJSLint = jsc.useJSLint;
	jsc.useJSLint = NO;
	
	// Add ourselves in the JS context
	[jsc evalJSString:@"var applicationController = NSApplication.sharedApplication.delegate"];
	
	//
	// Test disallowed getting
	//
	canGet		= NO;
	hadError	= NO;
	ret = [jsc evalJSString:@"NSWorkspace.sharedWorkspace"];
	if (!hadError)											return	@"delegate canGetProperty failed (1)";
	
	//
	// Test allowed getting
	//
	canGet		= YES;
	ret = [jsc evalJSString:@"NSWorkspace.sharedWorkspace"];
	if (!ret)												return	@"delegate canGetProperty failed (2)";
	if (object != [NSWorkspace class])						return	@"delegate canGetProperty failed (3)";
	if (![propertyName isEqualToString:@"sharedWorkspace"])	return	@"delegate canGetProperty failed (4)";

	//
	// Test getting
	//
	customValueGet = NULL;
	ret = [jsc evalJSString:@"NSWorkspace.sharedWorkspace"];
	if (object != [NSWorkspace class])						return	@"delegate getProperty failed (1)";
	if (![propertyName isEqualToString:@"sharedWorkspace"])	return	@"delegate getProperty failed (2)";
	
	o = [jsc unboxJSValueRef:ret];
	if (o != [NSWorkspace sharedWorkspace])					return	@"delegate getProperty failed (3)";
	
	
#define JSRESULTNUMBER JSValueToNumber([jsc ctx], ret?ret:JSValueMakeUndefined([jsc ctx]), NULL)
	
	//
	// Test custom getting
	//
	customValueGet = JSValueMakeNumber([jsc ctx], 123);
	ret = [jsc evalJSString:@"NSWorkspace.sharedWorkspace"];
	if (object != [NSWorkspace class])						return	@"delegate getProperty failed (4)";
	if (![propertyName isEqualToString:@"sharedWorkspace"])	return	@"delegate getProperty failed (5)";
	if (JSRESULTNUMBER != 123)		return	@"delegate getProperty failed (6)";
	customValueGet = NULL;



	//
	// Test disallowed setting
	//
	canSet		= NO;
	hadError	= NO;
	didSet		= NO;
	ret = [jsc evalJSString:@"var o = NSButtonCell.instance; o.bezelStyle = 0; o = null"];
	if (!hadError)				return	@"delegate canSetProperty failed (1)";

	//
	// Test allowed setting
	//
	canSet		= YES;
	ret = [jsc evalJSString:@"var o = NSButtonCell.instance; o.bezelStyle = 0; o.bezelStyle = 3; var r = o.bezelStyle; o = null; r"];
	if (!equalsButtonCell)		return	@"delegate canSetProperty failed (2)";
	if (!equalsBezelStyle)		return	@"delegate canSetProperty failed (3)";

	//
	// Test setting
	//
	customValueSet = NULL;
	ret = [jsc evalJSString:@"var o = NSButtonCell.instance; o.bezelStyle = 0; o.bezelStyle = 3; var r = o.bezelStyle; o = null; r"];
	int bezelStyle = JSRESULTNUMBER;
	if (bezelStyle != 3)		return	@"delegate setProperty failed (1)";
	

	//
	// Test custom setting
	//
	didSet		= YES;
	ret = [jsc evalJSString:@"var o = NSButtonCell.instance; o.bezelStyle = 0; o.bezelStyle = 3; var r = o.bezelStyle; o = null; r"];
	bezelStyle = JSRESULTNUMBER;
//	NSLog(@"bezelStyle=%d", bezelStyle);
	if (bezelStyle != 6)		return	@"delegate setProperty failed (2)";
	

	//
	// Test disallowed function
	//
	hadError	= NO;
	canCallC	= NO;
	ret = [jsc evalJSString:@"var p = NSMakePoint(1, 2); p.x+p.y"];
	if (!hadError)				return	@"delegate canCallC failed (1)";

	canCallC	= YES;
	ret = [jsc evalJSString:@"var p = NSMakePoint(15, 100); p.x+p.y"];
	int addResult = JSRESULTNUMBER;
	if (addResult != 115)		return	@"delegate canCallC failed (2)";
	
	
	
	
	//
	// Test disallowed calling
	//
	hadError	= NO;
	canCallObjC	= NO;
	canSet		= YES;
	canGet		= YES;
	didSet		= NO;
	ret = [jsc evalJSString:@"applicationController.add1(5)"];
	if (!hadError)				return	@"delegate canCallMethod failed (1)";

	hadError	= NO;
	ret = [jsc evalJSString:@"applicationController.get5"];
	if (!hadError)				return	@"delegate canCallMethod failed (2)";

	hadError	= NO;
	ret = [jsc evalJSString:@"applicationController.dummyValue = 8"];
	if (!hadError)				return	@"delegate canCallMethod failed (3)";

	//
	// Test allowed calling
	//
	hadError	= NO;
	canCallObjC	= YES;
	customValueCall	= NULL;
	ret = [jsc evalJSString:@"applicationController.add1(5)"];
	
	int add1Result1 = JSRESULTNUMBER;
	if (add1Result1 != 6)								return	@"delegate callMethod failed (1)";
	if (object != self)									return	@"delegate callMethod failed (2)";
	if (![methodName isEqualToString:@"add1:"])			return	@"delegate callMethod failed (3)";
	
	ret = [jsc evalJSString:@"applicationController.get5"];
	int get5Result1 = JSRESULTNUMBER;
	if (get5Result1 != 5)								return	@"delegate callMethod failed (4)";
	if (object != self)									return	@"delegate callMethod failed (5)";
	if (![methodName isEqualToString:@"get5"])			return	@"delegate callMethod failed (6)";

	ret = [jsc evalJSString:@"applicationController.dummyValue = 8"];
	if ([self dummyValue] != 8)							return	@"delegate callMethod failed (7)";
	if (object != self)									return	@"delegate callMethod failed (8)";
	if (![methodName isEqualToString:@"setDummyValue:"])return	@"delegate callMethod failed (9)";

	//
	// Test custom calling 
	//
	hadError	= NO;
	customValueCall	= JSValueMakeNumber([jsc ctx], 789);
	ret = [jsc evalJSString:@"applicationController.add1(5)"];
	int add1Result2 = JSRESULTNUMBER;
	if (add1Result2 != 789)								return	@"delegate callMethod failed (10)";
	
	ret = [jsc evalJSString:@"applicationController.get5"];
	int get5Result2 = JSRESULTNUMBER;
	if (get5Result2 != 789)								return	@"delegate callMethod failed (11)";
	customValueCall	= NULL;
	

	//
	// Test disallowed global getting
	//
	canCallObjC	= YES;
	canCallC	= YES;
	canGet		= YES;
	canSet		= YES;
	canGetGlobal= NO;
	ret = [jsc evalJSString:@"NSWorkspace"];
//	NSLog(@"ret=%x %x", ret, JSValueIsNull([jsc ctx], ret));
	if (ret)												return	@"delegate canGetGlobalProperty failed (1)";
	
	//
	// Test allowed global getting
	//
	canGetGlobal= YES;
	ret = [jsc evalJSString:@"NSWorkspace"];
	if (![propertyName isEqualToString:@"NSWorkspace"])		return	@"delegate canGetGlobalProperty failed (3)";
	
	
	//
	// Test global getting
	//
	customValueGetGlobal = NULL;
	ret = [jsc evalJSString:@"NSWorkspace"];
	if (![propertyName isEqualToString:@"NSWorkspace"])		return	@"delegate getGlobalProperty failed (1)";

	o = [jsc unboxJSValueRef:ret];
	if (o != [NSWorkspace class])							return	@"delegate getGlobalProperty failed (2)";
	
	//
	// Test custom global getting
	//
	customValueGetGlobal = JSValueMakeNumber([jsc ctx], 7599);
	ret = [jsc evalJSString:@"NSWorkspace"];
	if (![propertyName isEqualToString:@"NSWorkspace"])		return	@"delegate getGlobalProperty failed (3)";
	if (JSRESULTNUMBER != 7599)		return	@"delegate getGlobalProperty failed (4)";
	customValueGetGlobal = NULL;

	canGetGlobal= YES;

	//
	// Test script loading
	//
	id path = [NSString stringWithFormat:@"%@/Contents/Resources/Tests/0 blank.js", [[NSBundle mainBundle] bundlePath]];
//	NSLog(@"path=%@", path);
	
	canLoad = NO;
	BOOL evaled = [jsc evalJSFile:path];
	if (evaled)										return	@"delegate canLoad failed (1)";
	if (![pathtoJSFile isEqualToString:path])		return	@"delegate canLoad failed (2)";

	canLoad = YES;
	evaled = [jsc evalJSFile:path];
	if (!evaled)									return	@"delegate canLoad failed (3)";
	if (![pathtoJSFile isEqualToString:path])		return	@"delegate canLoad failed (4)";



	//
	// Test disallowed script evaling
	//
	canEval = NO;
	evaled = [jsc evalJSFile:path];
	if (evaled)										return	@"delegate canEval failed (1)";

	evaled = !![jsc evalJSString:@"2+2"];
	if (evaled)										return	@"delegate canEval failed (2)";


	//
	// Test allowed script evaling
	//
	canEval = YES;
	evaled = [jsc evalJSFile:path];
	if (!evaled)									return	@"delegate canEval failed (3)";

	evaled = !![jsc evalJSString:@"2+2"];
	if (!evaled)									return	@"delegate canEval failed (4)";

	//
	// Test custom script evaling
	//
	customScript = @"100+12";
	evaled = [jsc evalJSFile:path toJSValueRef:&ret];
	if (!evaled)											return	@"delegate custom eval failed (1)";
	if (JSRESULTNUMBER != 112)		return	@"delegate custom eval failed (2)";

	ret = [jsc evalJSString:@"2+2"];
	if (JSRESULTNUMBER != 112)		return	@"delegate custom eval failed (3)";
	if (![scriptToEval isEqualToString:@"2+2"])				return	@"delegate custom eval failed (4)";
	customScript = nil;
	
	jsc.useJSLint = useJSLint;
	
	return	nil;
}

- (id)testCallAPI
{
/*
	// This works but is tested only with NSLog

	id jscocoa = jsc;
	id str;
	str = @"2+2";
	NSLog(@"str=%@", [jscocoa eval:str]);
	str = @"2+'hello'";
	NSLog(@"str=%@", [jscocoa eval:str]);

	str = @"function hello(a, b) { return a + b } hello('bonjour', 'monde')";
	NSLog(@"str=%@", [jscocoa eval:str]);
	str = @"function dummyReturn() { return 'dummy!' }";
	NSLog(@"str=%@", [jscocoa eval:str]);

	str = @"dummyReturn";
	NSLog(@"call(%@)=%@", str, [jscocoa callFunction:str]);

	str = @"hello";
	NSLog(@"call(%@)=%@", str, [jscocoa callFunction:str withArguments:[NSArray arrayWithObjects:[NSNumber numberWithInt:100], [NSNumber numberWithInt:113], nil]]);
	str = @"hello";
	NSLog(@"call(%@)=%@", str, [jscocoa callFunction:str withArguments:[NSArray arrayWithObjects:[NSNumber numberWithFloat:1.23], [NSNumber numberWithFloat:4.56], nil]]);


	str = @"hello";
	NSLog(@"hasFunction(%@)=%d", str, [jscocoa hasFunction:str]);
	str = @"hello23";
	NSLog(@"hasFunction(%@)=%d", str, [jscocoa hasFunction:str]);
	
	str = @"function returnArray() { return [1, 2, [3], 'hello', [4, [5], [6, [7, 8]], 9]] }";
	[jscocoa eval:str];
	str = @"returnArray";
	NSLog(@"call(%@)=%@", str, [jscocoa callFunction:str]);

	str = @"function returnHash() { return { hello : 'world', array : [1, [2], {a:'b'}, 'z'], last : 'YES' } }";
	[jscocoa eval:str];
	str = @"returnHash";
	NSLog(@"call(%@)=%@", str, [jscocoa callFunction:str]);
*/	
	return nil;
}

- (int)add1:(int)a
{
	return	a+1;
}

int dummyValue;
- (void)setDummyValue:(int)value
{
	dummyValue = value;
}
- (int)dummyValue
{
	return	dummyValue;
}
- (int)get5
{
	return	5;
}


- (void) JSCocoa:(JSCocoaController*)controller hadError:(NSString*)error onLineNumber:(NSInteger)lineNumber atSourceURL:(id)url
{
//	NSLog(@"delegate exception handler : %@", error);
	hadError = YES;
}


- (BOOL) JSCocoa:(JSCocoaController*)controller canGetProperty:(NSString*)_propertyName ofObject:(id)_object inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;
{
//	NSLog(@"delegate canGet %@(%@).%@ canGet=%d", _object, [_object class], _propertyName, canGet);
	object			= _object;
	propertyName	= _propertyName;
	return	canGet;
}
- (JSValueRef) JSCocoa:(JSCocoaController*)controller getProperty:(NSString*)_propertyName ofObject:(id)_object inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;
{
//	NSLog(@"delegate get %@(%@).%@ customValueGet=%x", _object, [_object class], _propertyName, customValueGet);
	object			= _object;
	propertyName	= _propertyName;
	return	customValueGet;
}

- (BOOL) JSCocoa:(JSCocoaController*)controller canSetProperty:(NSString*)_propertyName ofObject:(id)_object toValue:(JSValueRef)_jsValue inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;
{
//	NSLog(@"delegate canSet %@(%@).%@", _object, [_object class], _propertyName);
	object			= _object;
	propertyName	= _propertyName;
	jsValue			= _jsValue;

	// Test here. Delaying after evalJSString returned could mean GC was triggered and we'd have invalid data.
	equalsButtonCell	= [_object class] == [NSButtonCell class];
	equalsBezelStyle	= [_propertyName isEqualToString:@"bezelStyle"];
	return	canSet;
}
- (BOOL) JSCocoa:(JSCocoaController*)controller setProperty:(NSString*)_propertyName ofObject:(id)_object toValue:(JSValueRef)_jsValue inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;
{
//	NSLog(@"delegate set");
	object			= _object;
	propertyName	= _propertyName;
	jsValue			= _jsValue;
	
	// Test here. Delaying after evalJSString returned could mean GC was triggered and we'd have invalid data.
	equalsButtonCell	= [_object class] == [NSButtonCell class];
	equalsBezelStyle	= [_propertyName isEqualToString:@"bezelStyle"];
	
	if (didSet)
	{
		[_object setBezelStyle:6];
//		NSLog(@"%@ %d", _object, [_object bezelStyle]);
	}
	
	return	didSet;
}


- (BOOL) JSCocoa:(JSCocoaController*)controller canCallFunction:(NSString*)_functionName argumentCount:(int)argumentCount arguments:(JSValueRef*)arguments inContext:(JSContextRef)ctx exception:(JSValueRef*)exception
{
//	NSLog(@"can call function %@", _functionName);
	functionName = _functionName;
	return	canCallC;
}
- (BOOL) JSCocoa:(JSCocoaController*)controller canCallMethod:(NSString*)_methodName ofObject:(id)_object argumentCount:(int)argumentCount arguments:(JSValueRef*)arguments inContext:(JSContextRef)ctx exception:(JSValueRef*)exception
{
//	NSLog(@"can call method %@.%@", _object, _methodName);
	object		= _object;
	methodName	= _methodName;
	return	canCallObjC;
}
- (JSValueRef) JSCocoa:(JSCocoaController*)controller callMethod:(NSString*)_methodName ofObject:(id)_object privateObject:(JSCocoaPrivateObject*)thisPrivateObject argumentCount:(int)argumentCount arguments:(JSValueRef*)arguments inContext:(JSContextRef)ctx exception:(JSValueRef*)exception
{
//	NSLog(@"custom method call %@.%@", _object, _methodName);
	
	object		= _object;
	methodName	= _methodName;
	return	customValueCall;
}

/*
- (JSValueRef) JSCocoa:(JSCocoaController*)controller willReturnValue:(JSValueRef)value inContext:(JSContextRef)ctx exception:(JSValueRef*)exception
{
	NSLog(@"willReturn");
	willReturn	= value;
	if (customValueReturn)	return	customValueReturn;
	return	value;
}
*/
- (BOOL) JSCocoa:(JSCocoaController*)controller canGetGlobalProperty:(NSString*)_propertyName inContext:(JSContextRef)ctx exception:(JSValueRef*)exception
{
//	NSLog(@"canGetGlobalProperty %@ %d", _propertyName, canGetGlobal);
	propertyName	= _propertyName;
	return	canGetGlobal;
}
- (JSValueRef) JSCocoa:(JSCocoaController*)controller getGlobalProperty:(NSString*)_propertyName inContext:(JSContextRef)ctx exception:(JSValueRef*)exception
{
//	NSLog(@"getGlobalProperty %@ %x", _propertyName, customValueGetGlobal);
	propertyName	= _propertyName;
	return	customValueGetGlobal;
}


- (BOOL)JSCocoa:(JSCocoaController*)controller canLoadJSFile:(NSString*)path
{
//	NSLog(@"canLoadJSFile=%@ canLoad=%d", path, canLoad);
	pathtoJSFile = path;
	return	canLoad;
}
// Check if script can be evaluated
- (BOOL)JSCocoa:(JSCocoaController*)controller canEvaluateScript:(NSString*)script
{
//	NSLog(@"canEvaluateScript=%@ canEval=%d", script, canEval);
	scriptToEval = script;
	return	canEval;
}
// Called before evalJSString, used to modify script about to be evaluated
//	Return a custom NSString (eg a macro expanded version of the source)
//	Return NULL to let JSCocoa handle evaluation
- (NSString*)JSCocoa:(JSCocoaController*)controller willEvaluateScript:(NSString*)script
{
//	NSLog(@"willEvaluateScript=%@ customScript=%@", script, customScript);
	scriptToEval = script;
	if (customScript)	return	customScript;
	return	script;
}



//
// JSCocoa inited from a WebView tests
//
- (id)testArray:(id)array
{
//	NSLog(@"array from WebView : %@", array);

	if (![[array objectAtIndex:0] isEqualToString:@"hello"])			return	nil;
	if (![[array objectAtIndex:1] isEqualToString:@"world"])			return	nil;
	if (![[array objectAtIndex:3] isEqualToString:@"end"])				return	nil;
	
	id subArray = [array objectAtIndex:2];
	if (!subArray)														return	nil;
	if (![subArray isKindOfClass:[NSArray class]])						return	nil;
	if ([[subArray objectAtIndex:0] intValue] != 4)						return	nil;
	if ([[subArray objectAtIndex:1] intValue] != 5)						return	nil;
	if ([[subArray objectAtIndex:2] intValue] != 6)						return	nil;

	return [NSArray arrayWithObjects:@"Hello", @"world", nil];
}

- (id)testHash:(id)hash
{
//	NSLog(@"hash from WebView : %@", hash);

	if (![[hash objectForKey:@"hello"] isEqualToString:@"world"])		return	nil;
	if (![[hash objectForKey:@"end"] isEqualToString:@"fin"])			return	nil;
	
	id subHash = [hash objectForKey:@"subHash"];
	if (!subHash)														return	nil;
	if (![[subHash objectForKey:@"part1"] isEqualToString:@"bonjour"])	return	nil;
	if (![[subHash objectForKey:@"part2"] isEqualToString:@"monde"])	return	nil;
	id subArray = [hash objectForKey:@"subArray"];
	if (!subArray)														return	nil;
	if ([[subArray objectAtIndex:0] intValue] != 11)					return	nil;
	if ([[subArray objectAtIndex:1] intValue] != 12)					return	nil;
	if ([[subArray objectAtIndex:2] intValue] != 13)					return	nil;
	
	return [NSDictionary dictionaryWithObjectsAndKeys:@"world", @"Hello", nil];
}

//
// Test37 - JSCocoa inited from a WebView — called back when the webpage has finished.
//
- (void)finishTest37:(BOOL)b
{
	if (!b)	return;
	[jsc callJSFunctionNamed:@"completeDelayedTest" withArguments:@"37 init from webview", [NSNumber numberWithInt:1], nil];

	[jsc2 release];
	for (id o in topObjects)
		[o release];
	[topObjects release];
	topObjects	= nil;
	jsc2		= nil;
/*	
	NSLog(@"****************");
	[JSCocoa logInstanceStats];
	[JSCocoa logBoxedObjects];
	NSLog(@"****************");
*/	
}

BOOL	bindingsAlreadyTested = NO;
BOOL	bindingsAlreadyTested2 = NO;

- (BOOL)bindingsAlreadyTested				{	if (cyclingContext)	return	NO; return	bindingsAlreadyTested;	}
- (BOOL)bindingsAlreadyTested2				{	if (cyclingContext)	return	NO; return	bindingsAlreadyTested2;	}
- (void)setBindingsAlreadyTested:(BOOL)b	{	bindingsAlreadyTested	= b;	}
- (void)setBindingsAlreadyTested2:(BOOL)b	{	bindingsAlreadyTested2	= b;	}

- (void)allTestsRanOK
{
	[window makeKeyAndOrderFront:nil];
	[textField setStringValue:@"All tests ran OK"];
}

- (NSError*)testNSError
{
	return	testNSError;
}

- (BOOL)callbackNSErrorWithClass:(NSErrorTest*)o
{
	if (testNSError)	
	{
		[testNSError release];
		testNSError = nil;
	}
	NSError* error = nil;
//	NSLog(@"calling with pointer %x", &error);
	BOOL r = [o someMethodReturningAnError:&error];

	if (error)
	{
		testNSError = error;
		[testNSError retain];
	}
	
	return	r;
}

- (BOOL)signatureTestWithError:(NSError**)error
{
	return NO;
}

- (bool)signatureTestWithError2:(NSError**)error andInt:(char)a
{
	return NO;
}

- (void)disposeClass:(NSString *)className
{
	id c = objc_getClass([className UTF8String]);
	if (!c)	return;
	objc_disposeClassPair(c);
}

- (void)disposeShadowBindingsClasses
{
	[self disposeClass:@"NSKVONotifying_BindingsSafeDeallocSource"];
	[self disposeClass:@"NSKVONotifying_NibTestOwner"];
}


@end
