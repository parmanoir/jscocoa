
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


