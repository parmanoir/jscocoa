
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

if (this.text)
{
	var cc = this.webView.mainFrame.globalContext.cc
	log('CC=' + cc)
	cc.text = this.text
}			
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
			log('there****************>>>>>>>>>>validateUserInterfaceItem'+anItem)
			return	YES;
		}

		- (NSUndoManager *)undoManager
		{
//			log('asking manager')
			if (!this._undoManager) this._undoManager = [NSUndoManager instance]
			return this._undoManager
		}
/*		
		- (BOOL)hasUndoManager
		{
			log('hasUndoManager')
			return YES
		}
*/		

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError 
{
	var e = null
	this.text = [NSString stringWithContentsOfURL:absoluteURL encoding:NSUTF8StringEncoding error:e]
//	this.webView.mainFrame.globalContext.cc
//	cc.text = str
	log('save data, wait for window to open')
	return	YES
}


		- (BOOL)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError
		{
/*
	log('save')
	log('outError=' + outError)
*/	
/*	
    NSString *localizedDescription = [mainBundle localizedStringForKey:[NSString stringWithFormat:@"description%ld", (long)code] value:@"Sketch could not complete the operation because an unknown error occurred. (IWASHERE)" table:@"SKTError"];
    NSString *localizedFailureReason = [mainBundle localizedStringForKey:[NSString stringWithFormat:@"failureReason%ld", (long)code] value:@"An unknown error occurred. (IWASHERE)" table:@"SKTError"];
    NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:localizedDescription, NSLocalizedDescriptionKey, localizedFailureReason, NSLocalizedFailureReasonErrorKey, nil];
*/
/*
	var info = {}
	log('==' + NSLocalizedDescriptionKey)
	log('==' + NSLocalizedFailureReasonErrorKey)
	info[NSLocalizedDescriptionKey] = '111111111111111'
	info[NSLocalizedFailureReasonErrorKey] = '22222222222222222222'
	memwrite(outError, [NSError errorWithDomain:NSCocoaErrorDomain code:0909 userInfo:info])
	log('==' + memread(outError))
	return false
*/
//	NSString 

//		log('wv=' + this.webView)
//		log('frame=' + this.webView.mainFrame.globalContext.cc.text)
		
		var str = this.webView.mainFrame.globalContext.cc.text
//		log(typeof str)
		var str = [NSString stringWithString:str]
		
		var e = null
		var b = [str writeToURL:absoluteURL atomically:YES encoding:NSUTF8StringEncoding error:e]
		return b
/*
		var b = [@'hello' writeToURL:absoluteURL atomically:YES encoding:NSUTF8StringEncoding error:e]

		var e = new outArgument
log('url=' + absoluteURL)
	var b = [NSString.stringWithString('hello') writeToURL:absoluteURL atomically:YES encoding:NSUTF8StringEncoding error:e]
	log('saved')
	log('e=' + e)
	return b
*/	
		}
		
		
		IBOutlet webView
	}


	class	WebHTMLView
	{
		swizzle - (void)keyDown:(id)sender
		{
			this.Original(arguments)
/*			
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
*/

			var page = this._frame.globalContext
			page.cc.exhaustDelayedPerforms()
//			doc.webView.windowScriptObject.evaluateWebScript('cc.exhaustDelayedPerforms()')
			

			var doc = this.window.windowController.document
			[doc updateChangeCount:0]
			
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
			this._frame.globalContext.cc.undo()
//			doc.undo()
		}
		- (void)redo:(id)sender
		{
			var doc = this.window.windowController.document
			this._frame.globalContext.cc.redo()
//			doc.undo()
		}

		swizzle- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item
		{
			log('this=' +this)
			log('this._frame=' + this._frame)
			var cc = this._frame.globalContext.cc
			log('cc=' + cc)
			if (item.action == 'undo:')	return cc.undoStack.length > 0
			if (item.action == 'redo:')	return cc.redoStack.length > 0
/*
			log('there*******************+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++' + item + '=' + item.action)

			log('===' + this.webView)
			log('===' + this._webView)
			log('===' + this.frame)
			log('===' + this._frame)
			log('===' + this.frameView)
			log('===' + this._frameView)
			log('===' + this._frame.globalContext.document)
*/
			return	this.Original(arguments)
		}
	}
	
	
//	detect insertText
//	editor : option to run XCode project (eg edit vec samples editor, then compile and run with XCode)
/*
	class	JSCocoaEditorWebView < WebView
	{
	}
*/	
	