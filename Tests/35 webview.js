
	// this is very fragile on i386. x86_64 works fine.


	//
	// Load Webkit
	//
	var loadedWebKit = ('WebView' in this)
	if (!loadedWebKit)
		var loaded = __jsc__.loadFrameworkWithName('WebKit')

	//
	// Frame load delegate
	//
	class WebViewLoadDelegate35 < NSObject
	{
		- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
		{
			// Global context is frame's window object
			var w = sender.mainFrame.globalContext
			
//			log('globalContext=' + w)

			var n = w.document.body
			
			//
			// Manipulate nodes and check results
			//
			
			// Paint the first P
			w.document.body.firstChild.nextSibling.style.backgroundColor = 'lime'
			w.document.body.childNodes[1].style.backgroundColor = 'lime'

			w.document.getElementById('hideMe').style.display = 'none'
			w.document.getElementById('showMe').style.display = 'block'
			w.document.getElementById('colorMe').style.backgroundColor = 'lime'

			var n = w.document.getElementById('replaceMe')
			w.replaceNodeValue(n, 8)
			if (w.document.getElementById('hideMe').style.display != 'none')			throw '(WebView) hiding div failed'
			if (w.document.getElementById('showMe').style.display != 'block')			throw '(WebView) revealing div failed'
			if (w.document.getElementById('colorMe').style.backgroundColor != 'lime')	throw '(WebView) coloring failed'
			if (w.document.getElementById('replaceMe').innerHTML != '8')				throw '(WebView) replacing content failed'

			w['eval']('function addMe(a, b) { return a+b}')
			if (w.addMe(3, 4) != 7)														throw '(WebView) adding a Javascript function failed'
			
			// Check for proper argument conversion while calling
			var externalString = w.externalString
			var nsString = [NSString stringWithString:externalString]
			if (externalString != 'Hello world from WebView !')							throw '(WebView) external string failed'
			if (nsString != 'Hello world from WebView !')								throw '(WebView) external string to NSString conversion failed'

			// Getting and setting properties from null and undefined values must fail
			// These must be returned as raw javascript values in this context, not boxed in a JSCocoaPrivateObject with externalJSValueRef
			var externalUndefined = w.externalUndefined

			var wentThrough1 = false
			try			{	externalUndefined.hello()	} 
			catch (e) 	{	wentThrough1 = true			}
			if (!wentThrough1)															throw '(WebView) external get failed'
			
			var wentThrough2 = false
			try			{	externalUndefined.someValue = 1.23	} 
			catch (e) 	{	wentThrough2 = true					}
			if (!wentThrough2)															throw '(WebView) external set failed'

			var wentThrough3 = false
			try			{	externalUndefined.call()	} 
			catch (e) 	{	wentThrough3 = true			}
			if (!wentThrough3)															throw '(WebView) external call failed'

			var wentThrough4 = false
			try			{	var n = new externalUndefined	} 
			catch (e) 	{	wentThrough4 = true				}
			if (!wentThrough4)															throw '(WebView) external new failed'
			
			
			// Send NSString, NSNumber, NSDictionary, NSHash in the WebView
			var str = [NSString stringWithString:'Hello welt']
			w.str = str
			if (w.str != str)															throw '(WebView) NSString conversion failed'

			var i = [NSNumber numberWithInt:123]
			w.i = i
			if (w.i != i)																throw '(WebView) NSNumber conversion failed'
			
			
			if ('undefinedVariable' in w)												throw '(WebView) undefined var should be undefined (1)'
			if ('undefinedVariable' in w.document)										throw '(WebView) undefined var should be undefined (2)'
			
			n = null

			loadDelegate = null
			window = null
			// ## This will close the window right now
			__jsc__.garbageCollect
			// Release the globalContext last
//			w = null
			__jsc__.garbageCollect

			completeDelayedTest('35 webview', true)
		}
		- (void)webView:(WebView *)sender willCloseFrame:(WebFrame *)frame
		{
//			log('willClose')
		}
		- (void)webView:(WebView *)webView didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
		{
//			log('didClear')
		}
	}

	// Build a window
	var rect = new NSRect(100, 100, 400, 400)
	var style = NSTitledWindowMask+NSClosableWindowMask+NSResizableWindowMask
	var window = NSWindow.alloc.initWithContentRect_styleMask_backing_defer(rect, style, NSBackingStoreBuffered, false)
	window.releasedWhenClosed = 0
	window.makeKeyAndOrderFront(null)
	window.release

	var contentView = window.contentView
	
	// Add a WebView
	var view = WebView.alloc.initWithFrame(contentView.frame)
	view.release
	var loadDelegate = WebViewLoadDelegate35.instance
	// WebView does NOT retain the delegate
	view.frameLoadDelegate = loadDelegate
	view.autoresizingMask = NSViewWidthSizable+NSViewHeightSizable
	contentView.addSubview(view)
	
//	log('shouldCloseWithWindow=' + view.shouldCloseWithWindow)
	
	var path = NSBundle.mainBundle.resourcePath + '/Tests/Resources/35 webView page.html'
//	path = 'http://yahoo.com'
	view.mainFrameURL = path

	view = null


	// The test won't be completed in this run loop cycle
	registerDelayedTest('35 webview')


