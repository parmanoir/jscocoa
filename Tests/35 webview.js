

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
//		- (void)webView:(WebView *)senderdidFinishLoadForFrame:(WebFrame *)frame
		- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
		{
//			log('LOADED')
//			log('k=' + sender.mainFrame.globalContext + '!!!!')
			
			var w = sender.mainFrame.globalContext
//			w.doStuff('blue')
//			log('r=' + r)

//log(w.document.body.innerHTML)
//return


//log('color=' + w.document.getElementById('colorMe').style.backgroundColor)
//log('node=' + w.document.body)
			var n = w.document.body
			
			w.replaceNodeValue(n, 'WORLD, time=' + (new Date))
			
			n.innerHTML = '****replaced****'
			n.style.backgroundColor = 'red'
			
//			n.style.backgroundColor = 'lime'
			
//			w.displayObject('replaceMe', '8')
//try
{
//			var n = w.document.getElementById('colorMe')
//			w.document.getElementById('colorMe').style.backgroundColor = 'blue'
//			log('n=' + n)
			}
//			catch(e)
			{
//				for (var i in e) log(i + '=' + e[i])
//				log('caught' + (typeof e))
			}
			
//			var node = w.document.getElementById('replaceMe')
//			log('node=' + node)
//			var n = w.doStuff('blue')
//			w.displayObject('replaceMe', this)
//			n = null

//			var n = w.document.getElementById('colorMe')
/*
			log('external document=' + n)
			n.style.backgroundColor = 'lime'
			
			w = null
			n = null
*/			
//			log('external document=' + w.location)
//			log('external document=' + w.document.location.href)
//			log('LL=' + sender.hash)
//			log('sig=' + sender.mainFrame.methodSignatureForSelector('globalContext'))
//			NSMethodSignature

//- (JSGlobalContextRef)globalContext

//			JSGlobalContextRef
//JSGlobalContextRef JSGlobalContextRetain(JSGlobalContextRef ctx);

			loadDelegate = null
			window = null
//			__jsc__.garbageCollect
		}
	}
	




//JSGlobalContextRef



	var rect = new NSRect(100, 100, 400, 400)
	var style = NSTitledWindowMask+NSClosableWindowMask+NSResizableWindowMask
	var window = NSWindow.alloc.initWithContentRect_styleMask_backing_defer(rect, style, NSBackingStoreBuffered, false)
	window.releasedWhenClosed = 0
	window.makeKeyAndOrderFront(null)
	window.release
	

	var contentView = window.contentView

	var view = WebView.alloc.initWithFrame(contentView.frame)
	view.release
	var loadDelegate = WebViewLoadDelegate35.instance()
//	var loadDelegate = WebViewLoadDelegate35.alloc.init
	// Does not retain the delegate
	view.frameLoadDelegate = loadDelegate
	view.autoresizingMask = NSViewWidthSizable+NSViewHeightSizable
	contentView.addSubview(view)
	
	log('shouldCloseWithWindow=' + view.shouldCloseWithWindow)

	
	var path = NSBundle.mainBundle.resourcePath + '/Tests/Resources/35 webView page.html'
//	path = 'http://yahoo.com'
	view.mainFrameURL = path

	view = null


//	registerWaitingTest('35 webview')
//	throw 'TEST'
	

