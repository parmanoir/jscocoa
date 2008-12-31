

	JSCocoaController.sharedController.evalJSFile(NSBundle.mainBundle.bundlePath + '/Contents/Resources/class.js')
	

	defineClass('ApplicationController < NSObject', {
		 runTests	: ['IBAction', function ()
						{
							JSCocoaController.log('Running tests …')
							
							var path = NSBundle.mainBundle.bundlePath + '/Contents/Resources/Tests'
							var r = JSCocoaController.sharedController.runTests(path)
							if (r) JSCocoaController.log('All tests OK')
						}]
		,garbageCollect	:	['IBAction', function ()
							{
								var count1 = JSCocoaController.JSCocoaPrivateObjectCount
								var count2 = JSCocoaController.JSCocoaHashCount
								var count3 = JSCocoaController.JSValueProtectCount
								JSCocoaController.garbageCollect
								var str = 'privateObject=' + count1 + '->' + JSCocoaController.JSCocoaPrivateObjectCount
								str += ' hash=' + count2 + '->' + JSCocoaController.JSCocoaHashCount
								str += ' valueProtect=' + count3 + '->' + JSCocoaController.JSValueProtectCount
								JSCocoaController.log('GC — ' + str)								
							}]
							
		,webView		:	'IBOutlet'
		,awakeFromNib	:	['void', 'void', function()
							{
								NSLogConsole.sharedConsole
								NSLogConsole.sharedConsole.webView = this.webView
								
								this.webView.window.setBottomCornerRounded(false)
//								this.perform({selector:'openClassTree:', withObject:null, afterDelay:0 })
								this.perform({selector:'runTests:', withObject:null, afterDelay:0 })
							}]

		// Running commands
		,inputScript	:	'IBOutlet'
		,runScript		:	['IBAction', function (sender)
							{
								var script = this.inputScript.stringValue
								if (sender && sender.respondsToSelector('length'))	script = sender

								var webView = NSLogConsole.sharedConsole.webView
								webView.startCommand(script)
								var result = JSCocoaController.sharedController.evalJSString(script)
								JSCocoaController.log(result)
								webView.endCommand
							}]
		,clearConsole	:	['IBAction', function ()
							{
								JSCocoaController.log('CLEAR')
								NSLogConsole.sharedConsole.webView.clear
							}]

		// Toggle sample commands
		,help			:	['IBAction', function ()
							{
								var webView = NSLogConsole.sharedConsole.webView
								if (!webView.isHelpOpen())	webView.openHelp
								else						webView.closeHelp
							}]



		// CocoaNav
		,cocoaNavWindow	:	'IBOutlet'
		,openClassTree	:	['IBAction', function ()
							{
								if (!this.cocoaNavWindow())
								{
									JSCocoaController.sharedController.evalJSFile(NSBundle.mainBundle.pathForResource_ofType('CocoaNavJS', 'js'))
									NSBundle.loadNibNamed_owner_('CocoaNavJS', this)
								}
								this.cocoaNavWindow.makeKeyAndOrderFront(this)
							}]
		// Google source homepage
		,openSourceHome	:	['IBAction', function ()
							{
								NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString('http://code.google.com/p/jscocoa/'))
							}]

		// Later : sample list
		,openSamples	:	['IBAction', function ()
							{
								JSCocoaController.log('SAMPLES')

							}]
							
		// Later : inject in apps, like F-Script
		,openInjector	:	['IBAction', function ()
							{
								JSCocoaController.log('INJECTOR')
							}]
	})

