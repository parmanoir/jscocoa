
	/*
		Querying Metadata With Spotlight
		http://developer.apple.com/technotes/tn2007/tn2192.html
	*/



	Class('JSCocoaDocument < NSDocument').definition = function ()
	{
		Method('readFromURL:ofType:error:').encoding('bool id id id').fn = function(url, type, error)
		{
//			log(url)
//			NSTask.launchedTaskWithLaunchPath_arguments('/Users/mini/Documents/xcode projects/Xcode build data/Debug/JSCocoaLauncher.app/Contents/MacOS/JSCocoaLauncher', NSArray.arrayWithObject('HELLO'))

			var existingTask = processes[url]
			if (existingTask)	existingTask.terminate

			var file = url.path.stringByReplacingOccurrencesOf({string:"\"", withString:"\\\""})

			var process = '/Users/mini/Documents/xcode projects/Xcode build data/Debug/JSCocoaSandbox.app/Contents/MacOS/JSCocoaSandbox'
			var task = NSTask.launchedTaskWithLaunchPath_arguments(process, NSArray.arrayWithObject(file))
		
			processes[url] = task
			
	
			this.perform({selector: 'closeRightAfterOpening:', withObject: null, afterDelay: 0})
			return	true
		}
		IBAction('closeRightAfterOpening').fn = function ()
		{
			this.close
		}
	}
	









		Class('ApplicationController < NSObject').definition = function ()
		{
			Method('applicationDidFinishLaunching:').encoding('void id').fn = function (notification)
			{
				appDelegate = this
				
				// Reparent progress indicator
				var themeView = this.window.contentView.superview
				themeView.addSubview(this.progressIndicator)
				// Set correct height and unhide it
				var frame = this.progressIndicator.frame
				frame.origin.y = themeView.subviews[0].frame.origin.y+1
				this.progressIndicator.frame = frame
				this.progressIndicator.hidden = false
				// Animate
				this.progressIndicator.startAnimation(null)

				// Window square corners + light bottom gradient
				this.window.bottomCornerRounded = false
				this.window['_setUsesLightBottomGradient:'](true)
				this.window.isVisible = true
				

				// Load a rowView to get its height
				NSBundle.loadNibNamed_owner('RowView', this)
				this.rowHeight = this.rowView.frame.size.height

				// Globals
				rowHeight	= appDelegate.rowHeight
				scrollView	= this.scrollView


				// Start query
				var query = NSMetadataQuery.instance()
//				var descriptors = NSArray.arrayWithObject(NSSortDescriptor.instance({withKey:'kMDItemFSName', ascending:true}))
//				query.setSortDescriptors(descriptors)
				
				
				NSNotificationCenter.defaultCenter.add({observer:NSApplication.sharedApplication.delegate, selector:'notified:', name:null, object:query})
				
				
//				mdfind "(kMDItemDisplayName = 'jscocoa*'cdw) && (kMDItemFSName = '*.jscocoa'c)"
//				query.setPredicate(NSPredicate.predicateWithFormat("(kMDItemFSName like [cd]'*\.jscocoa')"))
//				query.setPredicate(NSPredicate.predicateWithFormat("(kMDItemDisplayName like[cdw] '*jscocoa*') and (kMDItemFSName like[c] \"*\.jscocoa\")"))
//				query.setPredicate(NSPredicate.predicateWithFormat("(kMDItemFSName like[cdw] '*jscocoa*')"))
				query.setPredicate(NSPredicate.predicateWithFormat("(kMDItemDisplayName like[cdw] '*jscocoa*')"))
				query.startQuery


/*
log('====')
log('scrollView=' + this.scrollView)
log('scrollViewContent=' + this.scrollViewContent)
log('====')

var parentView = this.window.contentView
parentView = this.scrollViewContent




this.parentView = parentView

*/
/*
		NSBundle.loadNibNamed_owner('RowView', this)
parentView.addSubview(this.rowView)				
this.rowView.frame = NSMakeRect(0, h*1, w, h)
*/
/*
var frame = parentView.frame
log('parentView height=' + frame.size.height + ' ' + h*2)
//frame.size.height = h*2
frame.size.height = 20000
parentView.frame = frame
log(parentView.superview)
log(parentView.superview.superview)
log('contentView=' + parentView.superview.superview.contentView)
*/
/*
for (var i=0; i<5; i++)
{
		NSBundle.loadNibNamed_owner('RowView', this)
//		log('height=' + this.rowView.frame.size.height)
		
		var w = this.rowView.frame.size.width
		var h = this.rowView.frame.size.height
		parentView.addSubview(this.rowView)				
		this.rowView.frame = NSMakeRect(0, h*i, w, h)
		
}
*/
		


//		globalTEST = this.rowView

			}
			Method('applicationWillTerminate:').encoding('void id').fn = function (notification)
			{
				log('DIE')
				// Kill sub processes
				jsc.system('killall -9 JSCocoaSandbox')
	//			previousApplicationDelegate.applicationWillTerminate(notification)
			}
			Method('notified:').encoding('void id').fn = function (notification)
			{
				if (notification.name == 'NSMetadataQueryDidFinishGatheringNotification')	
				{
					this.progressIndicator.stopAnimation(null)
					this.progressIndicator.hidden = true

log('*********results**********')
				var l = notification.object.results.length
//				for (var i=0; i<l; i++)
//					log(notification.object.results[i].valueForAttribute('kMDItemPath'))// + '=' + notification.object.results[i].valueForAttribute('kMDItemContentModificationDate'))

				}
				
				spotLightNotified(notification)

//				var resultCount = notification.object.results.length
//				this.statusText.stringValue = resultCount + ' jscocoa' + (resultCount > 1 ? 's' : '')
				
//				var f = this.parentView.frame
//				f.size.height = resultCount*20
//				this.parentView.frame = f
	//	
	
//	NON RESTRIX A HOME -> SINON LES VOLUMES SON SOYRA TROUVE !
			
				log('GOT NOTIFICATION' + notification)
				log('count=' + notification.object.results.length)
/*
				for (var i=0; i<l; i++)
					log(notification.object.results[i].valueForAttribute('kMDItemFSName') + '=' + notification.object.results[i].valueForAttribute('kMDItemContentModificationDate'))
*/					
			}

			IBOutlet('window')

			IBOutlet('rowView')
			IBOutlet('scrollView')
			IBOutlet('scrollViewContent')

			IBOutlet('progressIndicator')
			IBOutlet('statusText')

		}
//		NSApplication.sharedApplication.delegate = ApplicationController.instance()



	Class('ListView < NSView').definition = function ()
	{
		Method('isFlipped').encoding('bool void').fn = function ()
		{
			return	true
		}
		Method('drawRect:').fn = function ()
		{
			var rect = this.superview.superview.documentVisibleRect
//			log('DRAWRECt ' + rect.origin.x + ' ' + rect.origin.y + ' ' + rect.size.width + ' ' + rect.size.height)
			listFrameChanged(this)

//if (!globalTEST)	return
//		var f = globalTEST.frame
//		globalTEST.frame = NSMakeRect(0, 0, f.size.w, f.size.h)

		}
	}
	
	
	
	function	spotLightNotified(notification)
	{
		log('notify result')
		results	= notification.object.results
		
		resultCount	= notification.object.results.length
		
		// Set frame size
		var frame = appDelegate.scrollViewContent.frame
		frame.size.height = resultCount*rowHeight
		appDelegate.scrollViewContent.frame = frame


		appDelegate.statusText.stringValue = resultCount + ' jscocoa' + (resultCount > 1 ? 's' : '')

	}
	function	listFrameChanged(list)
	{
		if (!scrollView)	return
		// STRUCT 
		log('notify frame change ' + scrollView + ' rect=' + scrollView.documentVisibleRect)
		
		var from = Math.floor(scrollView.documentVisibleRect.origin.y/rowHeight)
		var to = from + Math.ceil(scrollView.documentVisibleRect.size.height/rowHeight)
		if (to > results.length) to = results.length
		log('displaying from ' + from + ' to ' + to + ' (' + (to-from) + ')')


		var usedViews = []
		for (var i=from; i<to; i++)
		{
			var r = results[i]
			var v = getView()
			v.frameOrigin = { x : 0, y : rowHeight*i }
			usedViews.push(v)
			log('=>start add')
			log('superview=' + v.superview + ' parent=' + scrollView + ' ?=' + (v.superview==scrollView))
			scrollView.addSubview(v)
			log('=>END ADD')
		}
		
		for (var i=0; i<views.length; i++)
		{
			views[i].frameOrigin = { x : -30000, y : -30000 }
		}
		
		views = usedViews
/*		
		if (results.length < 100)	return
		var r = results[3]
		log('ATTS=' + r.valuesForAttributes(r.attributes))
		for (var i=0; i<results[0].attributes.length; i++)
		{
			log(results[0].attributes[i] + '=' + results[0].valueFor results[0].attributes
		}
		log('id=' + results[3].valueForAttribute('kMDItemID'))
*/		
	}
	
	var views = []
	function	getView()
	{
		if (views.length)	return	views.pop()
		
		log('*******************************!!!!!!!!SPAWN')
		
		// Load a rowView to get its height
		NSBundle.loadNibNamed_owner('RowView', appDelegate)
//		this.rowHeight = this.rowView.frame.size.height
		var view = appDelegate.rowView
		appDelegate.rowView = null
		return	view
	}

	
	/*

		TOFIX : rowView outlet in ListView !

	*/
	

	var appDelegate
	var resultCount
	var rowHeight
	var scrollView

	var processes = {}

	var results
