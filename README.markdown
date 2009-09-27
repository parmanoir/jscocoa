JSCocoa, a bridge from Javascript to Cocoa
==

With JSCocoa, you can write Cocoa applications (almost) entirely in Javascript or use it as a Plugin engine (like [Acorn ](http://gusmueller.com/blog/archives/2009/01/jscocoa_and_acorn_plugins_in_javascript.html) and [Spice](http://github.com/onecrayon/Spice-sugar)).
JSCocoa uses WebKit's Javascript framework, [JavascriptCore](http://webkit.org/projects/javascript/).

**JSCocoa is** a way to use Cocoa from Javascript. It works on the Mac (i386, x86_64, PPC), the iPhone and the iPhone simulator. You can write new Cocoa classes in Javascript, replace existing methods of classes by Javascript functions (swizzling them) and call Javascript functions on Cocoa objects (call <code>filter</code> on an <code>NSArray</code>, or use Javascript regular expressions on <code>NSString</code> with <code>myNSString.match(/pattern/)</code>).

JSCocoa can also be used as a replacement for the existing WebKit bridge, letting you use C functions, structs, and calling pretty much anything from your WebView. Access restriction can be setup by JSCocoa's delegate messages (<code>canGetProperty:ofObject:inContext:</code>, <code>canCallMethod:ofObject:argumentCount:arguments:</code>, etc.)

Basically, JSCocoa works like these bridges :

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

* [Spice-sugar](http://github.com/onecrayon/Spice-sugar) Spice.sugar allows the [Espresso text editor](http://macrabbit.com/espresso/) to be extended using JSCocoa
* [Narwhal-jsc](http://github.com/tlrobinson/narwhal-jsc/) A JavascriptCore + optional JSCocoa module for [Narwhal](http://github.com/tlrobinson/narwhal/tree) (Server-side Javascript)
* [JSTalk](http://github.com/ccgus/jstalk/) Gus Mueller, to let Cocoa applications be scripted in Javascript
* [PluginManager](http://github.com/Grayson/pluginmanager/) Grayson Hansard wrote a manager that enables you to write Cocoa plugins in AppleScript, F-Script, Javascript, Lua, Nu, Python and Ruby.
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

	// Unicode identifiers !
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
	JSCocoa* jsc = [JSCocoa new];

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
	id resultingObject = [jsc toObject:returnValue];
	
	// (Cleanup : only needed if you don't use ObjC's Garbage Collection)
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

