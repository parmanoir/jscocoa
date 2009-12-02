
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

			this.webView.setFrameLoadDelegate(this)
			this.webView.mainFrameURL = [[NSBundle mainBundle] pathForResource:'code colorer' ofType:'html']
			this.webView.setFrameLoadDelegate(this)
			
			doc = this
		}
		- (void)webView:(WebView *)senderdidFinishLoadForFrame:(WebFrame *)frame
		{
			log('loaded frame !!!!!!')
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
	}
	
	
//	detect insertText
//	editor : option to run XCode project (eg edit vec samples editor, then compile and run with XCode)
	
	