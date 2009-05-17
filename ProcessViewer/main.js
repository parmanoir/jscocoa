
	// Load Core Animation
	__jsc__.loadFrameworkWithName('QuartzCore')

	//
	// Window class, transparent background
	//
	class	ProcessWindow < NSWindow
	{
		- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
		{
			arguments[1] = NSBorderlessWindowMask
			var r = this.Super(arguments)
			r.backgroundColor	= NSColor.clearColor
			r.opaque			= false
			r.movableByWindowBackground = true
			return	r
		}
	}
	
	//
	// Layer class, derived only to hold js values
	//	Any class derived from an existing ObjC class gets a new instance variable,
	//	a Javascript hash, used to hold any Javascript value (or boxed ObjC object)
	//
	class	AppLayer < CALayer
	{
	}

	//
	// Core Animation view
	//
	class	ProcessView < NSView
	{
		//
		// On awake, build window
		//
		- (void)awakeFromNib
		{
			this.wantsLayer		= true
			var color = CGColorCreateGenericRGB(0, 0, 0, 0.85)
			this.layer.backgroundColor	= color
			CGColorRelease(color)
			this.layer.cornerRadius		= 5
			this.perform({selector:'postAwake', withObject:null, afterDelay:0})
		}
		//
		// After awake, build everything else
		//
		- (void)postAwake
		{
			this.containerLayer = CALayer.layer
			// Stick on middle top on resize
			this.containerLayer.autoresizingMask = kCALayerMinYMargin + kCALayerMaxYMargin + kCALayerMinXMargin + kCALayerMaxXMargin
			this.layer.addSublayer(this.containerLayer)

			this.buildUI

			transform = CATransform3DMakeRotation(0, 1, 0, 0)
			var zDistance = 600
			transform.m34 = 1.0 / -zDistance
			this.containerLayer.sublayerTransform = transform

			this.containerLayer.position = CGPointMake(this.frame.size.width/2, this.frame.size.height/2)

			// Get applications						
			var apps = NSFileManager.defaultManager.contentsOfDirectory({atPath:'/Applications', error:null})
			this.apps = apps.filteredArrayUsingPredicate(NSPredicate.predicateWithFormat("SELF ENDSWITH[c] '.app'"))

			var gridRatio = 5.5
			
			// Looking for column count to match an aspect ratio ...
			// columnCount = rowCount*aspectRatio
			// appCount = (apps.length =) surface area
			// columnCount*rowCount*aspectRatio = area
			var columnCount = Math.round(Math.sqrt(this.apps.length*gridRatio))
			var y = (this.apps.length/columnCount)/2
			var x = 0
			var startX = -columnCount/2
			var rowCount = Math.ceil(this.apps.length/columnCount)
			y = rowCount-1
			
			var startY = -80

			var roundness = 0.8
			
			var halfAngleSpan = Math.asin(roundness)
			var angleSpan = halfAngleSpan*2
			var circleCircumference = 2*Math.PI*1
			var arcLength = angleSpan*circleCircumference/(2*Math.PI)
			
			var projectedArcLength = -2*Math.cos(halfAngleSpan+Math.PI/2)

			var w = this.frame.size.width*Math.PI/projectedArcLength
w /= 3.6
			this.iconSize = arcLength*w/(columnCount-1)
			
			var zOffset = -(1-Math.cos(angleSpan/2))*w

			this.originalFrameWidth = this.frame.size.width

			// Holds applicationPath : layer
			this.appHash = {}
			
			// Build app arc
			for (var i=0; i<this.apps.length; i++)
			{
				var layers = createIconAndItsMirrorInLayer('/Applications/' + this.apps[i], this.containerLayer, this.iconSize)
				if (!layers)	continue

				var t = x/(columnCount-1)
				var angle = t*angleSpan-angleSpan/2

				// Set transform and position
				var transform = CATransform3DMakeRotation(-angle, 0, 1, 0)
				var cx = -Math.cos(angle+Math.PI/2)
				layers[0].transform = transform
				layers[0].zPosition = (1-Math.cos(angle))*w + zOffset
				
				// Use mirror transform on mirror layer
				var transform = CATransform3DMakeRotation(0, 1, 0, 0)
				transform.m22 = -1
				transform = CATransform3DConcat(layers[0].transform, transform)
				layers[1].transform = transform
				layers[1].zPosition = layers[0].zPosition

				this.appHash['/Applications/' + this.apps[i]] = layers

				// Make icons fall into place
				CATransaction.set({value:0, forKey:kCATransactionAnimationDuration})
				layers[0].position = CGPointMake(cx*w, y*this.iconSize+startY+300)
				layers[1].position = CGPointMake(cx*w, (-y-1)*this.iconSize+startY-300)
				CATransaction.commit
				layers[0].position = CGPointMake(cx*w, y*this.iconSize+startY)
				layers[1].position = CGPointMake(cx*w, (-y-1)*this.iconSize+startY)
				CATransaction.commit

				// Save original position and transforms in our custom layer class
				layers[0].originalTransform0	= layers[0].transform
				layers[0].originalTransform1	= layers[1].transform
				layers[0].originalPosition0		= layers[0].position
				layers[0].originalPosition1		= layers[1].position
				layers[0].originalZPosition		= layers[0].zPosition
				layers[0].originalBounds		= layers[0].bounds

				x++
				if (x >= columnCount)
				{
					x = 0
					y--
				}
			}
			// Register for workspace notifications : we'll use application launch and terminate
			var n = NSWorkspace.sharedWorkspace.notificationCenter
			n.add({observer:this, selector:'workspaceNotifies:', name:null, object:null})
			
			// Start displaying active apps after a short delay
			this.perform({selector:'updateLaunchedApplicationsList', withObject:null, afterDelay:0.4})

		}
		//
		// Build window title and window buttons as CALayers
		//
		- (void)buildUI
		{
			var style = NSMutableDictionary.dictionary
			style['font'] = 'HelveticaNeue-Bold'
			style['fontSize'] = 14

			var parentLayer = this.layer
			function	buildCircle(str, x, y)
			{
				// Circle layer
				var circleRadius = 16
				var c		= CALayer.layer
				c.bounds	= CGRectMake(0, 0, circleRadius, circleRadius)
				c.position	= CGPointMake(x, y)
				c.borderColor = CGColorGetConstantColor(kCGColorWhite)
				c.borderWidth = 2
				c.cornerRadius = circleRadius/2
				parentLayer.addSublayer(c)
				// Inner text layer (x, - , +)
				var t		= CATextLayer.layer						
				t.string	= str
				t.style		= style
				var s		= t.preferredFrameSize
				t.bounds	= CGRectMake(0, 0, s.width, s.height)
				t.position	= CGPointMake(circleRadius/2+1, circleRadius/2+1)
				c.addSublayer(t)
				
				// Stick on top on resize
				c.autoresizingMask = kCALayerMinYMargin
			}
			var y = this.frame.size.height-16
			var x = 16
			buildCircle('x', x+0, y)
			buildCircle('-', x+20, y)
			buildCircle('+', x+40, y)

			// Application title
			var t		= CATextLayer.layer						
			t.style		= style
			t.string	= 'A Javascript Process Viewer'
			var s		= t.preferredFrameSize
			t.bounds	= CGRectMake(0, 0, s.width, s.height)
			t.position	= CGPointMake(this.frame.size.width/2, y)
			parentLayer.addSublayer(t)
			// Stick on middle top on resize
			t.autoresizingMask = kCALayerMinYMargin + kCALayerMinXMargin + kCALayerMaxXMargin

			// Kill button
			var t		= CATextLayer.layer						
			t.opacity	= 0
			t.string	= '    Kill    '
			t.style		= style
			var s		= t.preferredFrameSize
			t.bounds	= CGRectMake(0, 0, s.width, s.height)
			t.position	= CGPointMake(this.frame.size.width/2, 35)
			t.borderColor	= CGColorGetConstantColor(kCGColorWhite)
			t.borderWidth	= 2
			t.cornerRadius	= 9
			parentLayer.addSublayer(t)
			// Stick on middle bottom on resize
			t.autoresizingMask = kCALayerMaxYMargin + kCALayerMinXMargin + kCALayerMaxXMargin
			this.killButton = t
		}


		//
		// Create application lists as CALayers
		//
		- (void)updateLaunchedApplicationsList
		{
			// Update launched applications list
			var launchedApplications = NSWorkspace.sharedWorkspace.launchedApplications

			var launchedApplicationCount = launchedApplications.length-2
			if (launchedApplicationCount > 0)	this.pitchLayers(0.2)
			else								this.pitchLayers(0)
			var launchedIconSize = 128

			// Compute icon size and list origin
			var totalSize = launchedApplicationCount*launchedIconSize
			var x = -totalSize/2+launchedIconSize/2
			if (totalSize > this.originalFrameWidth)	
			{
				launchedIconSize = this.originalFrameWidth/launchedApplicationCount
				x = -this.originalFrameWidth/2+launchedIconSize/2
			}
			
			if (!this.previousLaunchedApplicationsList)	this.previousLaunchedApplicationsList = {}
			var launchedApplicationsList = {}

			// Display each active application icon
			for (var i=0; i<launchedApplications.length; i++)
			{
				var app = launchedApplications[i]
				// Skip finder and ourselves
				if (app.NSApplicationName == 'Finder' || app.NSApplicationName == 'JSCoreAnimation')	continue
				
				launchedApplicationsList[String(app.NSApplicationPath)] = true

				var layers
				if (app.NSApplicationPath in this.appHash)
					layers = this.appHash[app.NSApplicationPath]
				else
				{
					layers = createIconAndItsMirrorInLayer(app.NSApplicationPath, this.containerLayer, launchedIconSize)
					this.appHash[app.NSApplicationPath] = layers
				}
				// Display icon
				var y = -130
				var l = layers[0]
				l.position = CGPointMake(x, y)
				l.zPosition = 0
				l.bounds = CGRectMake(0, 0, launchedIconSize, launchedIconSize)
				l.transform = CATransform3DMakeScale(1, 1, 1)
				l.opacity = 1
				// Display icon mirror
				var l = layers[1]
				l.position = CGPointMake(x, y-launchedIconSize)
				l.zPosition = 0
				l.bounds = CGRectMake(0, 0, launchedIconSize, launchedIconSize)
				var transform = CATransform3DMakeScale(1, 1, 1)
				transform.m22 = -1
				l.transform = transform
				l.opacity = 0.2
				x += launchedIconSize
			}
			// Compare current and previous list, remove inactive applications
			var applicationPath = '/Applications/'
			for (var path in this.previousLaunchedApplicationsList)
			{
				if (!(path in launchedApplicationsList))
				{
					var layers = this.appHash[path]
					// If application is in '/Applications/', push it back in the arena
					if (path.substr(0, applicationPath.length) == applicationPath)
					{
						pitchLayerAndItsMirror(layers, this.pitchAngle, this.pitchDistance)
						layers[0].bounds	= layers[0].originalBounds
						layers[1].bounds	= layers[0].originalBounds
						layers[1].opacity = 0.1
					}
					else
					// Application came from elsewhere, fade it out
					{
						layers[0].transform = CATransform3DMakeScale(0.01, 0.01, 0.01)
						layers[0].opacity = 0
						layers[1].transform = CATransform3DMakeScale(0.01, 0.01, 0.01)
						layers[1].opacity = 0
					}
				}
			}
			this.previousLaunchedApplicationsList = launchedApplicationsList
		}

		//
		// Rotate layers about the X axis
		//
		- (void)pitchLayers:(float)angle
		{
			if (this.pitchAngle == angle)	return

			var layers			= this.containerLayer.sublayers
			this.pitchAngle		= angle
			this.pitchDistance	= angle == 0 ? 0 : 80

			// Pitch layers
			for (var appName in this.appHash)
				pitchLayerAndItsMirror(this.appHash[appName], this.pitchAngle, this.pitchDistance)
		}


		//
		// Check NSWorkspace notifications to know when apps are launched and killed
		//
		- (void)workspaceNotifies:(id)notification
		{
			if (notification.name == 'NSWorkspaceDidLaunchApplicationNotification' || notification.name == 'NSWorkspaceDidTerminateApplicationNotification')	
				this.updateLaunchedApplicationsList
		}
		
		- (void)mouseDragged:(NSEvent*)event
		{
			this.dragged = true
		}
		- (void)mouseUp:(NSEvent*)event
		{
			// Return if we dragged
			var dragged = this.dragged
			this.dragged = false
			if (dragged)	return

			var p = NSPointToCGPoint(this.convert({point:event.locationInWindow, fromView:null}))
			
			// Clicked close, minimize, maximize
			if (p.x < 70 && p.y >= this.frame.size.height-25)
			{ 
				// Close : fade and terminate
						if (p.x < 27)	this.layer.opacity = 0, NSApplication.sharedApplication.perform({selector:'terminate:', withObject:null, afterDelay:0.5})
				// Minimize
				else	if (p.x < 47)	this.window.miniaturize(null)
				// Maximize
				else
				{
					// Save initial frame size
					if (!this.initialSize)		this.initialSize = { w : this.window.frame.size.width, h : this.window.frame.size.height }
					var newSize = this.window.frame.size.width == this.initialSize.w ? { w : 330, h : 200 } : this.initialSize
					var newY = newSize.h == 200 ? this.window.frame.origin.y+200 : this.window.frame.origin.y-200
					// Rescale layer to fill view
					this.window.set({frame:NSMakeRect(this.window.frame.origin.x, newY, newSize.w, newSize.h), display:true})
					this.viewDidEndLiveResize
				}
				return
			}

			var hit = this.layer.hitTest(p)
			// Clicked back row
			if (hit.zPosition !=0)	NSWorkspace.sharedWorkspace.openFile(hit.applicationPath)
			// Clicked front row : kill
			else		
			{
				// Find pid
				var launchedApplications = NSWorkspace.sharedWorkspace.launchedApplications
				for (var i=0; i<launchedApplications.length; i++)
				{
					var app = launchedApplications[i]
					if (app.NSApplicationPath == hit.applicationPath)
					{
						this.killButton.string = '     Kill ' + app.NSApplicationName + '     '
						var s = this.killButton.preferredFrameSize
						this.killButton.bounds = CGRectMake(0, 0, s.width, s.height)

						this.pendingPidToKill = app.NSApplicationProcessIdentifier

						CATransaction.set({value:0, forKey:kCATransactionAnimationDuration})
						this.killButton.opacity = 1
						CATransaction.commit
						CATransaction.set({value:7, forKey:kCATransactionAnimationDuration})
						// Zero opacity will not hit our kill button layer, but the layer behind
						this.killButton.opacity = 0.00001
						CATransaction.commit
					}
				}
			}

			// Clicked kill button
			if (hit.valueOf() == this.killButton.valueOf() && this.killButton.presentationLayer.opacity > 0.1)
			{
				if (this.pendingPidToKill)		JSCocoaController.sharedController.system('kill -9 ' + this.pendingPidToKill)
				this.pendingPidToKill	= 0
				this.killButton.opacity	= 0
			}
		}

		- (void)viewDidEndLiveResize
		{
			CATransaction.begin
			CATransaction.set({value:0, forKey:kCATransactionAnimationDuration})
			var s = this.frame.size.width / this.originalFrameWidth
			transform = CATransform3DMakeScale(s, s, s)
			var zDistance = 600
			transform.m34 = 1.0 / -zDistance
			this.containerLayer.sublayerTransform = transform
			CATransaction.commit
		}
	}

	//
	// Helper methods
	//
	
	function	createIconAndItsMirrorInLayer(applicationPath, parentLayer, iconSize)
	{
		// Get application icon as a CGImage
		var image = NSWorkspace.sharedWorkspace.iconForFile(applicationPath)
		if (!image)	return	null
//		var cgImage = image.bestRepresentationForDevice(null).CGImage
		var cgImage = image.representations[0]
		if (!cgImage)	return
		cgImage = cgImage.CGImage

		// Icon layer
		var l = AppLayer.layer
		l.applicationPath = String(applicationPath)
		l.contents = cgImage
		l.bounds = CGRectMake(0, 0, iconSize, iconSize)
		l.anchorPoint = CGPointMake(0.5, 0)
		parentLayer.addSublayer(l)

		// Mirror layer
		var l2 = CALayer.layer
		l2.contents = cgImage
		l2.bounds = l.bounds
		l2.opacity = 0.1
		l2.anchorPoint = CGPointMake(0.5, 1)
		parentLayer.addSublayer(l2)
		
		return	[l, l2]
	}
	
	function	pitchLayerAndItsMirror(layers, angle, deltaY)
	{
		var x = layers[0].originalPosition0.x
		var y = layers[0].originalPosition0.y
		var z = layers[0].originalZPosition
		var y2 = y*Math.cos(angle) - z*Math.sin(angle)
		var z2 = y*Math.sin(angle) + z*Math.cos(angle)
		layers[0].position = CGPointMake(x, y2+deltaY)
		layers[0].zPosition = z2
		layers[0].transform = CATransform3DConcat(layers[0].originalTransform0, CATransform3DMakeRotation(angle, 1, 0, 0))

		var x = layers[0].originalPosition1.x
		var y = layers[0].originalPosition1.y
		var z = layers[0].originalZPosition
		var y2 = y*Math.cos(angle) - z*Math.sin(angle)
		var z2 = y*Math.sin(angle) + z*Math.cos(angle)
		layers[1].position = CGPointMake(x, y2+deltaY)
		layers[1].zPosition = z2
		layers[1].transform = CATransform3DConcat(layers[0].originalTransform1, CATransform3DMakeRotation(angle, 1, 0, 0))
	}

