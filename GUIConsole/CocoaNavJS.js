
	defineClass('CocoaNavView < WebView', {
		 awakeFromNib	:	['void', 'void', function()
							{
								this.setFrameLoadDelegate(this)
								this.mainFrame.loadRequest(NSURLRequest.requestWithURL(NSURL.fileURLWithPath(NSBundle.mainBundle.pathForResource_ofType('CocoaNavJS', 'html'))));
								this.setPolicyDelegate(this)
							}]
		,'webView:didFinishLoadForFrame:' : ['void', 'id', 'id', function (webView, frame)
		{
			this.refresh(null)
		}]
	
		,refresh		:	['IBAction', function (sender)
							{
								var list = JSCocoaHelper.classList
								this.windowScriptObject.call({webScriptMethod:'loadClassesFromText', withArguments:NSArray.arrayWithObject(list)})
							}]

		,'webView:decidePolicyForNavigationAction:request:frame:decisionListener:' : ['void', 'id', 'id', 'id', 'id', 'id', function (webview, actionInformation, request, frame, listener )
							{
								NSWorkspace.sharedWorkspace.openURL(request.URL)

							}]

	})





	defineClass('CocoaNavJSWindow < NSWindow', {
		 searchField		:	'IBOutlet'
		,webView		:	'IBOutlet'
		,'performFind:' : ['IBAction', function (sender)
		{
			this.makeFirstResponder(this.searchField)
		}]
		,'searchFieldChanged:' : ['IBAction', function (sender)
		{
			this.webView.windowScriptObject.call({webScriptMethod:'search', withArguments:NSArray.arrayWithObject(sender.stringValue)})

		}]
		,'performFindNext:' : ['IBAction', function (sender)
		{
			this.webView.windowScriptObject.call({webScriptMethod:'nextSearchResult', withArguments:null})
		}]
		,'performFindPrev:' : ['IBAction', function (sender)
		{
			this.webView.windowScriptObject.call({webScriptMethod:'prevSearchResult', withArguments:null})
		}]
	})
