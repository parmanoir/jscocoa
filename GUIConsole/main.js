

	__jsc__.evalJSFile(NSBundle.mainBundle.bundlePath + '/Contents/Resources/class.js')
	

	//
	// Application controller, our app delegate
	//
	class	ApplicationController < NSObject
	{
		IBAction runTests
		{
			JSCocoaController.log('Running tests …')
			
			var path = NSBundle.mainBundle.bundlePath + '/Contents/Resources/Tests'
			var r = __jsc__.runTests(path)
			if (r) JSCocoaController.log('All tests OK')
		}
		
		IBAction garbageCollect
		{
			__jsc__.garbageCollect
			JSCocoa.logInstanceStats
		}
							
		IBOutlet	webView
		- (void)awakeFromNib
		{
			NSLogConsole.sharedConsole
			NSLogConsole.sharedConsole.webView = this.webView

			this.webView.window.setBottomCornerRounded(false)
//			this.perform({selector:'openClassTree:', withObject:null, afterDelay:0 })
//			this.perform({selector:'runTests:', withObject:null, afterDelay:0 })
		}

		// Running commands
		IBOutlet	inputScript
		IBAction	runScript
		{

			// Take input from our text box outlet
			var script = this.inputScript.stringValue
			// Check if our first param is the script to be evaluated
			if (sender && sender.respondsToSelector('length'))	script = sender

			var webView = NSLogConsole.sharedConsole.webView
			webView.startCommand(script)
			result = eval(String(script))
			JSCocoaController.log(String(result))
			webView.endCommand
		}
		IBAction	clearConsole
		{
			NSLogConsole.sharedConsole.webView.clear
		}

		// Toggle sample commands
		IBAction	help
		{
			var webView = NSLogConsole.sharedConsole.webView
			if (!webView.isHelpOpen)	webView.openHelp
			else						webView.closeHelp
		}



		// CocoaNav
		IBOutlet	cocoaNavWindow
		IBAction	openClassTree
		{
			if (!this.cocoaNavWindow)
			{
				JSCocoaController.sharedController.evalJSFile(NSBundle.mainBundle.pathForResource_ofType('CocoaNavJS', 'js'))
				NSBundle.loadNibNamed_owner_('CocoaNavJS', this)
			}
			this.cocoaNavWindow.makeKeyAndOrderFront(this)
		}
		// Github source homepage
		IBAction	openSourceHome
		{
			NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString('http://github.com/parmanoir/jscocoa/tree/master/'))
		}

		// Later : sample list
		IBAction	openSamples
		{
			JSCocoaController.log('SAMPLES')
		}
							
		// Later : inject in apps, like F-Script
		IBAction	openInjector
		{
			JSCocoaController.log('INJECTOR')
		}
	}
