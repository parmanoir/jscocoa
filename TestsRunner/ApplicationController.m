//
//  ApplicationController.m
//  TestsRunner
//
//  Created by Patrick Geiller on 17/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ApplicationController.h"
#import "JSCocoa.h"

@implementation ApplicationController

JSCocoaController* jsc = nil;

//- (void)awakeFromNib
- (void)applicationDidFinishLaunching:(id)notif
{
	Dl_info info;
	// Get info about a JavascriptCore symbol
	dladdr(dlsym(RTLD_DEFAULT, "JSClassCreate"), &info);
	
	BOOL runningFromSystemLibrary = [[NSString stringWithUTF8String:info.dli_fname] hasPrefix:@"/System"];
	if (!runningFromSystemLibrary)	NSLog(@"***Running a nightly JavascriptCore***");
	if ([NSGarbageCollector defaultCollector])	NSLog(@"***Running with ObjC Garbage Collection***");
//[[NSGarbageCollector defaultCollector] disable];
	
//	NSLog(@"DEALLOC AUTORELEASEPOOL");
//	[JSCocoaController deallocAutoreleasePool];
//	[[NSAutoreleasePool alloc] init];




//	jsc = [JSCocoaController sharedController];
	jsc = [JSCocoa new];




//	[[JSCocoaController sharedController] evalJSFile:[[NSBundle mainBundle] pathForResource:@"class" ofType:@"js"]];
/*	
	JSValueRef v;
	v = [[JSCocoaController sharedController] callJSFunctionNamed:@"test1" withArguments:[NSNumber numberWithInt:3], [NSNumber numberWithInt:5], @"hello!!", nil];
	NSLog(@">>RET=%@", [[JSCocoaController sharedController] formatJSException:v]);
	v = [[JSCocoaController sharedController] callJSFunctionNamed:@"test2" withArguments:nil];
	NSLog(@">>RET=%@", [[JSCocoaController sharedController] formatJSException:v]);
*/	
//	[[JSCocoaController sharedController] callJSFunctionNamed:@"test1" withArguments:self];
/*
	JSValueRef value = [[JSCocoaController sharedController] callJSFunctionNamed:@"test1" withArguments:@"myself", nil];
	id object;
	id object2 = [[JSCocoaController sharedController] unboxJSValueRef:value];
	[JSCocoaFFIArgument unboxJSValueRef:value toObject:&object inContext:[[JSCocoaController sharedController] ctx]];
	NSLog(@"result=*%@*%@*", object, object2);
*/	
	
/*
	NSRect rect = { 10, 20, 30, 40 };
	NSRect rect1, rect2;
	NSDivideRect(rect, &rect1, &rect2, 5, 0);
	float* r;
	r = &rect;	NSLog(@"r=%f, %f, %f, %f", r[0], r[1], r[2], r[3]);
	r = &rect1;	NSLog(@"r1=%f, %f, %f, %f", r[0], r[1], r[2], r[3]);
	r = &rect2;	NSLog(@"r2=%f, %f, %f, %f", r[0], r[1], r[2], r[3]);
*/	

/*
	CGColorRef color = CGColorCreateGenericRGB(1.0, 0.8, 0.6, 0.2);
	const CGFloat* colors = CGColorGetComponents(color);
	NSLog(@"%f %f %f %f %f", colors[0], colors[1], colors[2], colors[3], colors[4]);
	
	CGColorRelease(color);
*/
	[[NSApplication sharedApplication] setDelegate:self];
	[self performSelector:@selector(runJSTests:) withObject:nil afterDelay:0];
//	[self performSelector:@selector(runJSTests:) withObject:nil afterDelay:0];
}

- (void)applicationWillTerminate:(id)notif
{
	[jsc unlinkAllReferences];
	[jsc garbageCollect];
	NSLog(@"willTerminate %@ JSCocoa retainCount=%d", jsc, [jsc retainCount]);
	if ([jsc retainCount] != 1)	NSLog(@"***Invalid JSCocoa retainCount***");
	[jsc release];
	
	id path = [NSString stringWithFormat:@"%@/Contents/Resources/Tests/! stock", [[NSBundle mainBundle] bundlePath]];
	id files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
	if ([files count])	NSLog(@"***warning, skipping tests***"), NSLog(@"%@", files);
}


//
// Run unit tests + delegate tests
//
int runCount = 0;

- (IBAction)runJSTests:(id)sender
{
	runCount++;
	jsc.delegate = nil;
	id path = [[NSBundle mainBundle] bundlePath];
	path = [NSString stringWithFormat:@"%@/Contents/Resources/Tests", path];
//	NSLog(@"Run %d from %@", runCount, path);
	int count = [jsc runTests:path];
	BOOL b = !!count;
	[self garbageCollect:nil];

	// Test delegate
	id error = nil;
	error = [self testDelegate];
/*
//	[jsc evalJSString:@"var applicationController = NSApplication.sharedApplication.delegate"];
//[[NSGarbageCollector defaultCollector] collectExhaustively];
JSValueRef res;
	res = [jsc evalJSString:@"NSApplication.sharedApplication"];
	NSLog(@"res=%@", [jsc unboxJSValueRef:res]);
	[self garbageCollect:nil];
	res = [jsc evalJSString:@"NSApplication.sharedApplication"];
	NSLog(@"res=%@", [jsc unboxJSValueRef:res]);
*/
	if (error)
	{
		b = NO;
		path = error;
	}
	jsc.delegate = nil;
	
	if (!b)	{	NSLog(@"!!!!!!!!!!!FAIL %d from %@", runCount, path); return; }
	else	NSLog(@"All %d tests ran OK !", count);
}

//
// GC
//
- (IBAction)garbageCollect:(id)sender
{
	[jsc garbageCollect];
}


- (IBAction)runSimpleTestFile:(id)sender
{
	id js = @"2+2";
	js = @"NSWorkspace.sharedWorkspace.activeApplication";

	js = @"var a = NSMakePoint(2, 3)";


	[JSCocoaController garbageCollect];
//	JSValueRefAndContextRef v = [[JSCocoaController sharedController] evalJSString:js];
//	JSValueRefAndContextRef v = [jsc evalJSString:js];
	JSValueRef ret = [jsc evalJSString:js];
	[JSCocoaController garbageCollect];
	
//	JSStringRef resultStringJS = JSValueToStringCopy(v.ctx, v.value, NULL);
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
	
	//
	// Test custom getting
	//
	customValueGet = JSValueMakeNumber([jsc ctx], 123);
	ret = [jsc evalJSString:@"NSWorkspace.sharedWorkspace"];
	if (object != [NSWorkspace class])						return	@"delegate getProperty failed (4)";
	if (![propertyName isEqualToString:@"sharedWorkspace"])	return	@"delegate getProperty failed (5)";
	if (JSValueToNumber([jsc ctx], ret, NULL) != 123)		return	@"delegate getProperty failed (6)";
	customValueGet = NULL;



	//
	// Test disallowed setting
	//
	canSet		= NO;
	hadError	= NO;
	didSet		= NO;
	ret = [jsc evalJSString:@"var o = NSButtonCell.instance(); o.bezelStyle = 0; o = null"];
	if (!hadError)				return	@"delegate canSetProperty failed (1)";

	//
	// Test allowed setting
	//
	canSet		= YES;
	ret = [jsc evalJSString:@"var o = NSButtonCell.instance(); o.bezelStyle = 0; o.bezelStyle = 3; var r = o.bezelStyle; o = null; r"];
	if (!equalsButtonCell)		return	@"delegate canSetProperty failed (2)";
	if (!equalsBezelStyle)		return	@"delegate canSetProperty failed (3)";

	//
	// Test setting
	//
	customValueSet = NULL;
	ret = [jsc evalJSString:@"var o = NSButtonCell.instance(); o.bezelStyle = 0; o.bezelStyle = 3; var r = o.bezelStyle; o = null; r"];
	int bezelStyle = JSValueToNumber([jsc ctx], ret, NULL);
	if (bezelStyle != 3)		return	@"delegate setProperty failed (1)";
	

	//
	// Test custom setting
	//
	didSet		= YES;
	ret = [jsc evalJSString:@"var o = NSButtonCell.instance(); o.bezelStyle = 0; o.bezelStyle = 3; var r = o.bezelStyle; o = null; r"];
	bezelStyle = JSValueToNumber([jsc ctx], ret, NULL);
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
	int addResult = JSValueToNumber([jsc ctx], ret, NULL);
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
	int add1Result1 = JSValueToNumber([jsc ctx], ret, NULL);
	if (add1Result1 != 6)								return	@"delegate callMethod failed (1)";
	if (object != self)									return	@"delegate callMethod failed (2)";
	if (![methodName isEqualToString:@"add1:"])			return	@"delegate callMethod failed (3)";
	
	ret = [jsc evalJSString:@"applicationController.get5"];
	int get5Result1 = JSValueToNumber([jsc ctx], ret, NULL);
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
	int add1Result2 = JSValueToNumber([jsc ctx], ret, NULL);
	if (add1Result2 != 789)								return	@"delegate callMethod failed (10)";
	
	ret = [jsc evalJSString:@"applicationController.get5"];
	int get5Result2 = JSValueToNumber([jsc ctx], ret, NULL);
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
	if (JSValueToNumber([jsc ctx], ret, NULL) != 7599)		return	@"delegate getGlobalProperty failed (4)";
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
	if (JSValueToNumber([jsc ctx], ret, NULL) != 112)		return	@"delegate custom eval failed (2)";

	ret = [jsc evalJSString:@"2+2"];
	if (JSValueToNumber([jsc ctx], ret, NULL) != 112)		return	@"delegate custom eval failed (3)";
	if (![scriptToEval isEqualToString:@"2+2"])				return	@"delegate custom eval failed (4)";
	customScript = nil;

	return	nil;
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
- (JSValueRef) JSCocoa:(JSCocoaController*)controller callMethod:(NSString*)_methodName ofObject:(id)_object argumentCount:(int)argumentCount arguments:(JSValueRef*)arguments inContext:(JSContextRef)ctx exception:(JSValueRef*)exception
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



@end
