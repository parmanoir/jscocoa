JSCocoa, a bridge from Javascript to Cocoa
==

JSCocoa lets you use Cocoa in Javascript. You can write Cocoa applications (almost) entirely in Javascript, or use it as a Plugin engine, like [Acorn does](http://gusmueller.com/blog/archives/2009/01/jscocoa_and_acorn_plugins_in_javascript.html).
JSCocoa uses WebKit's Javascript framework, [JavascriptCore](http://webkit.org/projects/javascript/).

**JSCocoa is** a way to use Cocoa from a Mac desktop app or from the iPhone simulator. (iPhone coming up after I implement Tim Burk's method pool to sidestep iPhone's disabled mprotect).
It works just like other bridges :

* [RubyCocoa](http://rubycocoa.sourceforge.net/), [MacRuby](http://www.macruby.org/) write Cocoa in Ruby
* [PyObjC](http://pyobjc.sourceforge.net/) write Cocoa in Python
* [LuaCore](http://gusmueller.com/lua/) write Cocoa in Lua

**JSCocoa isn't** a Javascript framework to use on the Web. For that, check out :

* [Cappuccino](http://cappuccino.org/) an open source framework that makes it easy to build desktop-caliber applications that run in a web browser
* [SproutCore](http://www.sproutcore.com/) makes building javascript applications fun and easy

Contribute and discuss
--

* [Discussion group](http://groups.google.com/group/jscocoa) Questions ? Join the Google group and ask away !
* [Twitter](http://twitter.com/parmanoir) Tweet me questions and comments
* [Github](http://github.com/parmanoir/jscocoa/tree/master) fork JSCocoa from Github, add changes, and notify me with a pull request
* [Documentation](http://code.google.com/p/jscocoa/w/list) on Google Code

Who uses it ?
--

* [JSTalk](http://github.com/ccgus/jstalk/tree/master) Gus Mueller, to let Cocoa applications be scripted in Javascript
* [PluginManager](http://github.com/Grayson/pluginmanager/tree/master) Grayson Hansard wrote a manager that enables you to write Cocoa plugins in AppleScript, F-Script, Javascript, Lua, Nu, Python and Ruby.
* [Elysium](http://lucidmac.com/products/elysium/) Matt Mower, to script Elysium, a MIDI sequencer
* [Acorn Plugins](http://gusmueller.com/blog/archives/2009/01/jscocoa_and_acorn_plugins_in_javascript.html) Gus Mueller, to let Acorn users write [Acorn](http://flyingmeat.com/acorn/) plugins in Javascript
* [Interactive console for iPhone](http://ido.nu/kuma/2008/11/22/jscocoa-interactive-console-for-iphone/) Kumagai Kentaro wrote a console to interact with the iPhone simulator from a web page !
* [JSCocoaCodaLoader](http://gusmueller.com/blog/archives/2008/11/jscocoacodaloader.html) write Javascript plugins that work in [Coda](http://www.panic.com/coda/)
* [REPL console](http://tlrobinson.net/blog/2008/10/10/command-line-interpreter-and-repl-for-jscocoa/) Tom Robinson's command line interface

Are you missing on that list ? [Send me a mail !](mailto:parmanoir@gmail.com)


What does it look like ?
--
Use straight Javascript syntax to call Cocoa.

	// Get current application name
	var appName = NSWorkspace.sharedWorkspace.activeApplication.NSApplicationName

	// Alloc an object (need to release)
	var button = NSButton.alloc.initWithFrame(NSMakeRect(0, 0, 100, 40))
	// Alloc an object (no need to release)
	var button = NSButton.instance({ withFrame:NSMakeRect(0, 0, 100, 40) }) 

	// Setting
	var window = NSWorkspace.sharedWorkspace.activeApplication.keyWindow
	// Instead of calling setTitle ...
	window.setTitle('new title')
	// ... set the 'title' property
	window.title = 'new title'

	// Call methods with jQuery-like syntax
	obj.call({ withParam1:'Hello', andParam2:'World' }) 
	obj['callWithParam1:andParam2:']('Hello', 'World') 
	obj.callWithParam1_andParam2('Hello', 'World' )

	// Unicode ! Javascript is fully Unicode compliant, so is JSCocoa
	function	追加する(最初の, 次の)	{	return 最初の+ 次の }
	var 結果 = 追加する('こんにちは', '世界')
	NSApplication.sharedApplication.keyWindow.title = 結果

	// Define a new Javascript class usable by Cocoa (inspired by Cappucino)
	class MyClass < NSObject
	{
		// Custom drawing, calling parent method
		- (void)drawRect:(NSRect)rect
		{
			// do some drawing here
			...
			// Call parent method
			this.Super(arguments)			
		}
		// Class method
		+ (float)addFloatX:(float)x andFloatY:(float)y
		{
			return x + y
		}
	}

	// Manipulate an existing class
	class NSButton
	{
		// Add a method to an existing class
		- (void)someNewMethod:(NSString*)name
		{
			...
		}

		// Swizzle an instance method of an existing class
		Swizzle- (void)drawRect:(NSRect)rect
		{
			// Draw something behind the button
			...
			// Call original swizzled method
			this.Original(arguments)
			// Draw something in front of the button
			NSBezierPath.bezierPathWithOvalInRect(rect).stroke
		}
	}


Starting up
--
This will start a controller, eval a file, call a Javascript method and get an ObjC object out of it. You can start multiple interpreters, e.g. one for each document.

	// Start
	JSCocoaController* jsc = [JSCocoa new];

	// Eval a file
	[jsc evalJSFile:@"path to a file"];
	// Eval a string
	[jsc evalJSString:@"log(NSWorkspace.sharedWorkspace.activeApplication.NSApplicationName)"];
	
	// Add an object of ours to the Javascript context
	[jsc setObject:self withName:@"controller"];

	// Call a Javascript method - we can use any object we added with setObject
	JSValueRef returnValue = [jsc callJSFunctionNamed:@"myJavascriptFunction" withArguments:self, nil];
	// The return value might be a raw Javascript value (null, true, false, a number) or an ObjC object
	// To get an ObjC object
	id resultingObject = [jsc unboxJSValueRef:returnValue];
	
	// Once we're done, let's cleanup and release
	// This will remove all existing ObjC objects left in the Javascript context
	[jsc unlinkAllReferences];
	[jsc garbageCollect];
	// Destroy
	[jsc release];


Add it to your project
--
Going the framework route :

* Build JSCocoa/JSCocoa.xcodeproj
* Add built JSCocoa.framework to your project
* import <JSCocoa/JSCocoa.h>

No framework, adding JSCocoa files into your project :

* Drag the JSCocoa folder in your project
* Delete irrelevant files (Info.plist, JSCocoa_Prefix.pch, English.lproj, project files)
* Add the JavascriptCore framework
* In 'Build' project settings, add -lffi to 'Other linker flags'
* import "JSCocoa.h"


Thanks !
--
* Gus Mueller — Distant Object code
* Jonathan 'Wolf' Rentzsch — JRSwizzle

Questions, comments, patches
--
Send me a mail !

Patrick Geiller<br/> [parmanoir@gmail.com](mailto:parmanoir@gmail.com)

