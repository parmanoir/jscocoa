
var doc
	class	MyDocument < NSDocument
	{
	
	
		- (NSString *)windowNibName
		{
			return 'MyDocument'
		}
		
		- (void)windowControllerDidLoadNib:(NSWindowController *) aController
		{
			log('webView=' + this.webView)
			
//			this.webView.mainFrameURL = 'http://www.google.com'

//			this.webView.setFrameLoadDelegate(this)
			url = [[NSBundle mainBundle] pathForResource:'code colorer' ofType:'html']
			var localUrl = 'file:///Users/mini/Sites/lintex/code%20colorer.html'
			url = localUrl
			if (url == localUrl)	log('***loading LOCAL colorer***')
			
			this.webView.mainFrameURL = url
			this.webView.frameLoadDelegate = this
			
			doc = this
		}
		- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
		{
			this.page = this.webView.mainFrame.globalContext
//			this.webView.mainFrame.globalContext.eval('document.body.style.backgroundColor = "red"')
//			this.webView.mainFrame.globalContext.document.body.style.backgroundColor = 'blue'
			this.page.cc.captureUndo = false
		}

		- (void)undo:(id)sender
		{
			log('undo2')
		}

		- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
		{
			log('there****************>>>>>>>>>>')
			return	YES;
		}
		
		IBOutlet webView
	}


	class	WebHTMLView
	{
		swizzle - (void)keyDown:(id)sender
		{
			this.Original(arguments)
			
//			log(this)

			var v = this
			while (v)
			{
				log('v=' + v)
				v = v.superview
			}
			log('=====')
//			this.webView.webScriptObject.evaluateWebScript('document.body.innerHTML="hello"')
//log('d='+ doc.webView)
//			doc.webView.windowScriptObject.evaluateWebScript('document.body.innerHTML="hello"')
			doc.webView.windowScriptObject.evaluateWebScript('cc.exhaustDelayedPerforms()')
		}


		- (void)undo:(id)sender
		{
/*
			log('undo')
			log('view=' + this)
			log('window=' + this.window)
			log('windowController=' + this.window.windowController)
			log('document=' + this.window.windowController.document)
*/			
			var doc = this.window.windowController.document
//			doc.undo()
		}
		- (void)redo:(id)sender
		{
			var doc = this.window.windowController.document
//			doc.undo()
		}

		swizzle- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item
		{
			log('there*******************+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++' + item + '=' + item.action)
			log('===' + this.webView)
			log('===' + this._webView)
			log('===' + this.frame)
			log('===' + this._frame)
			log('===' + this.frameView)
			log('===' + this._frameView)
			log('===' + this._frame.globalContext.document)
			return	NO;
		}
	}
	
	
//	detect insertText
//	editor : option to run XCode project (eg edit vec samples editor, then compile and run with XCode)

	class	JSCocoaEditorWebView < WebView
	{
	}
	
	