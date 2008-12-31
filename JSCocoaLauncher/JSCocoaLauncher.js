
//
// Put your Javascript code here. It will be called on application delegate's awakeFromNib.
//








//	SET NSMENU TITLE ! JSCocoaLauncher -> Test2.js. De mem pour le nom alt-tab + dock


// + NSLogConsole TITLE !

/*
	function	openJSCocoaFile(file)
	{
//		log('JSOPENING=' + file)
//		log('ARGS=' + NSProcessInfo.processInfo.arguments)
		
		var args = NSProcessInfo.processInfo.arguments
		var process = args[0]
		
		process = '/Users/mini/Documents/xcode projects/Xcode build data/Debug/JSCocoaSandbox.app/Contents/MacOS/JSCocoaSandbox'
		var task = NSTask.launchedTaskWithLaunchPath_arguments(process, NSArray.arrayWithObject(file))
		log(task.processIdentifier)
	}
*/


//NSTask.launchedTaskWithLaunchPath_arguments('/Applications/Preview.app/Contents/MacOS/Preview', NSArray.array)

//log('launched')

//jsc.system('/Applications/Preview.app/Contents/MacOS/Preview &')

/*
@interface JSCocoaDocument : NSDocument
@end
@implementation JSCocoaDocument

- (id)init
{
	id r = [super init];
	NSLog(@"LKLKL");
	return	r;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError;
{
	NSLog(@"THERE");
	return	YES;
}

@end
*/
//kMDItemFSName
//kMDItemDisplayName


	/*
		Querying Metadata With Spotlight
		http://developer.apple.com/technotes/tn2007/tn2192.html
	*/


	var processes = {}

	Class('JSCocoaDocument < NSDocument').definition = function ()
	{
		Method('readFromURL:ofType:error:').encoding('bool id id id').fn = function(url, type, error)
		{
//			log(url)
//			NSTask.launchedTaskWithLaunchPath_arguments('/Users/mini/Documents/xcode projects/Xcode build data/Debug/JSCocoaLauncher.app/Contents/MacOS/JSCocoaLauncher', NSArray.arrayWithObject('HELLO'))

			var existingTask = processes[url]
			if (existingTask)	existingTask.terminate

			var file = url.path.stringByReplacingOccurrencesOf({string:"\"", withString:"\\\""})

//			openJSCocoaFile(file)
			
			
			
			
//		var args = NSProcessInfo.processInfo.arguments
//		var process = args[0]
		
			var process = '/Users/mini/Documents/xcode projects/Xcode build data/Debug/JSCocoaSandbox.app/Contents/MacOS/JSCocoaSandbox'
			var task = NSTask.launchedTaskWithLaunchPath_arguments(process, NSArray.arrayWithObject(file))
		
			processes[url] = task
			
	
//	[[JSCocoaController sharedController] evalJSString:str];
//	[self performSelector:@selector(closeRightAfterOpening) withObject:nil afterDelay:0];
			this.perform({selector: 'closeRightAfterOpening:', withObject: null, afterDelay: 0})
			return	true
		}
		IBAction('closeRightAfterOpening').fn = function ()
		{
			this.close
		}
	}
	
/*
	Class('ApplicationNotificationObserver < NSObject').definition = function ()
	{
	}
	
*/

//	var previousApplicationDelegate = NSApplication.sharedApplication.delegate
	
//	function	openJSCocoaList()
//	{
		
		Class('ApplicationController < NSObject').definition = function ()
		{
			Method('applicationDidFinishLaunching:').encoding('void id').fn = function (notification)
			{
				var themeView = this.window.contentView.superview
				// Reparent indicator
				themeView.addSubview(this.progressIndicator)
				// Set correct height and unhide it
				var frame = this.progressIndicator.frame
				frame.origin.y = themeView.subviews[0].frame.origin.y+1
				this.progressIndicator.frame = frame
				this.progressIndicator.hidden = false
				// Animate
				this.progressIndicator.startAnimation(null)
				

				// Start query
				var query = NSMetadataQuery.instance()
//				var descriptors = NSArray.arrayWithObject(NSSortDescriptor.instance({withKey:'kMDItemFSName', ascending:true}))
//				query.setSortDescriptors(descriptors)
				
				
				NSNotificationCenter.defaultCenter.add({observer:NSApplication.sharedApplication.delegate, selector:'notified:', name:null, object:query})
				
				
//				mdfind "(kMDItemDisplayName = 'jscocoa*'cdw) && (kMDItemFSName = '*.jscocoa'c)"
//				query.setPredicate(NSPredicate.predicateWithFormat("(kMDItemFSName like [cd]'*\.jscocoa')"))
				query.setPredicate(NSPredicate.predicateWithFormat("(kMDItemDisplayName like[cdw] '*jscocoa*') and (kMDItemFSName like[c] \"*\.jscocoa\")"))
				query.startQuery
				
				
				

				jsc.loadFrameworkWithName('QuartzCore')
				
				var v = this.customCAView
				v.wantsLayer = true
				v.layer.backgroundColor = CGColorCreateGenericRGB(0, 0, 0, 0.4)
				
				var parentLayer = v.layer
				// Créé un nouveau layer
				var layer			= CALayer.layer

				layer.position = CGPointMake(200, 110)

				layer.bounds		= CGRectMake(0, 0, 120*1.75, 120)
				layer.backgroundColor = CGColorGetConstantColor(kCGColorWhite)
				parentLayer.addSublayer(layer)

				// Coins arrondis
				layer.cornerRadius	= 16
				layer.masksToBounds	= true

				// Charge une image de fond
				var imagePath = '/Users/mini/Pictures/iPhoto Library/Originals/2002/Album/conic.gif'
				//				var imagePath = '/Users/mini/Pictures/iPhoto Library/Originals/2008/Larians/IMG_3038.JPG'
				var imagePath = '/Users/mini/Desktop/Z.png'
				imagePath = '/Users/mini/Sites/JSCocoa Core Animation sample/Z.png'
				layer.contents = NSImage.instance({withContentsOfFile:imagePath}).bestRepresentationForDevice(null).CGImage


				// Tourne
				layer.transform = CATransform3DMakeRotation(0.3, 0, 0, 1)


				// Rajoute une bordure jaune
				layer.borderWidth = 4
				layer.borderColor = CGColorCreateGenericRGB(1, 0.8, 0, 1)
//layer.style = { opacity : 1.0, borderColor : CGColorCreateGenericRGB(0, 1, 0, 1), cornerRadius : 4 }
layer.style = { opacity : 0.5 }
//log('style=' + layer.style)
//				layer.borderColor = CGColorCreateGenericRGB(0, 100.0, 0, 1)
//return
				// Rajoute un filtre
				//				var filter = CIFilter.filterWithName('CIMotionBlur')
				var filter = CIFilter.filterWithName('CIZoomBlur')
				filter.setDefaults
//				layer.filters = NSArray.arrayWithObject(filter)
				layer.filters = [filter]




				// Change les paramètres du filtre
				filter.set({value:100, forKey:'inputAmount'})
				filter.set({value:1.1, forKey:'inputAmount'})

//				return
				
				
//				filter.set({value:1, forKey:'inputRadius'})
//				CIFilter* filter = [CIFilter filterWithName:@"CIBloom"];
//				[filter setDefaults];
//				[filter setValue:[NSNumber numberWithFloat:10.0] forKey:@"inputRadius"];
//				[filter setValue:[NSNumber numberWithFloat:2.0] forKey:@"inputIntensity"];
//				starfieldLayer.filters = [NSArray arrayWithObject:filter];
				
				
				
//				kCGColorWhite
				
			}
			Method('applicationWillTerminate:').encoding('void id').fn = function (notification)
			{
				log('DIE')
				// Kill sub processes
				jsc.system('killall -9 JSCocoaSandbox')
	//			previousApplicationDelegate.applicationWillTerminate(notification)
			}
			IBOutlet('customCAView')
			IBOutlet('window')
			IBOutlet('progressIndicator')
			Method('notified:').encoding('void id').fn = function (notification)
			{
				if (notification.name == 'NSMetadataQueryDidFinishGatheringNotification')	
				{
					this.progressIndicator.stopAnimation(null)
					this.progressIndicator.hidden = true

log('*********results**********')
				var l = notification.object.results.length
				for (var i=0; i<l; i++)
					log(notification.object.results[i].valueForAttribute('kMDItemPath'))// + '=' + notification.object.results[i].valueForAttribute('kMDItemContentModificationDate'))

				}
	//	
	
//	NON RESTRIX A HOME -> SINON LES VOLUMES SON SOYRA TROUVE !
			
				log('GOT NOTIFICATION' + notification)
				log(notification.object.results.length)
/*
				for (var i=0; i<l; i++)
					log(notification.object.results[i].valueForAttribute('kMDItemFSName') + '=' + notification.object.results[i].valueForAttribute('kMDItemContentModificationDate'))
*/					
			}



		}
		NSApplication.sharedApplication.delegate = ApplicationController.instance()
/*
		Class('JSCocoaListController < NSObject').definition = function ()
		{
			Method('applicationWillTerminate:').encoding('void id').fn = function (notification)
			{
				log('DIE')
				previousApplicationDelegate.applicationWillTerminate(notification)
			}
			IBOutlet('window')
			IBOutlet('progressIndicator')
		}
*/		
//		NSApplication.sharedApplication.delegate = LauncherApplicationController.instance()
		
		
//		var jsCocoaList = JSCocoaListController.instance()
		
//		NSBundle.loadNibNamed_owner('JSCocoaList', jsCocoaList)
//		jsCocoaList.window.makeKeyAndOrderFront(null)
//	}




	var progressIndicator
	function	createProgressIndicator(window)
	{
/*	
		progressIndicator = NSProgressIndicator.instance()
		progressIndicator.frame = new NSRect(0, 0, 16, 16)
		progressIndicator.controlSize = NSMiniControlSize
		progressIndicator.style = NSProgressIndicatorSpinningStyle
		window.contentView.addSubview(progressIndicator)
		progressIndicator.setAutoresizingMask
		progressIndicator.startAnimation(null)
*/		
	}


/*
//	log(jsCocoaList.progressIndicator)
	jsCocoaList.window.contentView.superview.addSubview(jsCocoaList.progressIndicator)
	log(jsCocoaList.window.contentView.superview)
	
	var frame = jsCocoaList.progressIndicator.frame
	frame.origin.y = jsCocoaList.progressIndicator.superview.subviews[0].frame.origin.y+1
	jsCocoaList.progressIndicator.frame = frame
	
	jsCocoaList.progressIndicator.startAnimation(null)
*/	
//	log('hep' + jsCocoaList.progressIndicator.superview)
//	return



	
	
	
	
