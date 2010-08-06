
	/*
	
		Drag the shape ...
			* from inside its bounds to change its shape
			* from outside its bounds to rotate it
	
	*/



	//
	// Application Delegate
	//
	@implementation iPhoneTest2AppDelegate : NSObject

		- (void)applicationDidFinishLaunching:(UIApplication *)application
		{
			// Table view background
			this.viewController.view.backgroundColor = UIColor.groupTableViewBackgroundColor
			this.window.addSubview(this.viewController.view)
			this.window.makeKeyAndVisible

			[this performSelector:'repaintPolygon' withObject:null afterDelay:0]
		}
		// Shouldn't be needed !
		- (void)repaintPolygon
		{
			[this.viewController.polygonView setNeedsDisplay]
		}
		IBOutlet window
		IBOutlet viewController

	@end


	//
	// View controller
	//
	@implementation iPhoneTest2ViewController : UIViewController

		- (void)loadView
		{
			myTableView = [UITableView instanceWithFrame:UIScreen.mainScreen.applicationFrame style:0]
			myTableView.delegate	= this
			myTableView.dataSource	= this
			myTableView.autoresizesSubviews = true
			this.view = myTableView
//			this.polygonView.pointCount = 5
			this.Super(arguments)
			[this initCells]
		}
		- (void)initCells
		{
			var cell0 = [UITableViewCell instance]
			var cell1 = [UITableViewCell instance]
			
			var bounds = this.view.bounds
			var margin = 50

			// Slider
			var slider = [UISlider instanceWithFrame:new CGRect(margin, 12, bounds.size.width-margin*2, 10)]
			[cell0 addSubview:slider]

			// Image buttons
			var imageButton = [UIButton instanceWithFrame: new CGRect(25, 19, 12, 10)]
			var image = UIImage.imageNamed('lowPointCount.png')
			[imageButton setImage:image forState:0]
			[cell0 addSubview:imageButton]

			var imageButton = [UIButton instanceWithFrame: new CGRect(bounds.size.width-38, 19, 12, 10)]
			var image = UIImage.imageNamed('hiPointCount.png')
			[imageButton setImage:image forState:0]
			[cell0 addSubview:imageButton]

			// Text label
			var label = [UILabel instanceWithFrame: new CGRect(20, 8, 200, 30)]
			label.text = /*String(new Date)*/ 'Fill Polygon'
			label.font = UIFont.boldSystemFontOfSize(18)
			[cell1 addSubview:label]

			// Switch
			var onoff = [UISwitch instanceWithFrame: new CGRect(200, 9, bounds.size.width-margin*2, 80)]
			[cell1 addSubview:onoff]

			this.cells = [cell0, cell1]

			// UIControlEventAllEvents (0xFFFFFFFF) does not work anymore. ##checkwhy
			[slider addTarget:this action:'pointCountChanged:' forControlEvents:1 << 12]
			[onoff addTarget:this action:'fillModeChanged:' forControlEvents:1 << 12]
			
			slider.value = 0
		}
		
		//
		// Table view
		//
		- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
		{
			return	1
		}
		- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
		{
			return	2
		}
		- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
		{
			if (!this.cells)
			{
				[this initCells]
			}
			return	this.cells[indexPath.row]
		}

		//
		// Actions
		//
		- (void)fillModeChanged:(id)sender
		{
			this.polygonView.isFilled = sender.isOn==1 ? true : false
			[this.polygonView setNeedsDisplay]
		}
		- (void)pointCountChanged:(id)sender
		{
			var pointCount = Math.round(sender.value*10+5)
			if (pointCount < 5 || pointCount > 15)
			{
				log('out of bounds pointCount=' + pointCount)
				if (pointCount < 5)		pointCount = 5
				if (pointCount > 15)	pointCount = 15
			}
			
			this.polygonView.pointCount = pointCount
			[this.polygonView setNeedsDisplay]
		}
		
		//
		// Outlets
		//
		IBOutlet labelView
		IBOutlet polygonView
	@end
	
	
	//
	// Polygon view
	//
	@implementation PolygonView : UIView

		- (void)drawRect:(CGRect)rect
		{
			var bounds = this.bounds
			var w = this.bounds.size.width/2
			var h = this.bounds.size.height/2
//			log('DRAW ' + this.pointCount + '*' + bounds.size.width + ' ' + this.isFilled)
			
			var scale = h*0.9
			if (!this.pointCount)
			{
				this.pointCount = 5
				this.backgroundColor = UIColor.groupTableViewBackgroundColor
				this.angleOffset = 0
				this.currentAngleOffset = 0
				this.dynamicScale = scale/2
			}
			this.backgroundColor = UIColor.groupTableViewBackgroundColor
			
			var ctx = UIGraphicsGetCurrentContext()
			CGContextSetShadow(ctx, new CGSize(0, -10), 4)
			// Using string 'kCGColorWhite' instead of constant — BAD — ##tocheck
			CGContextSetFillColorWithColor(ctx, CGColorGetConstantColor('kCGColorWhite'))
			CGContextSetStrokeColorWithColor(ctx, CGColorGetConstantColor('kCGColorWhite'))
			
			for (var i=0; i<=this.pointCount*2; i++)
			{
				var a = Math.PI*2*(i/(this.pointCount*2)) + this.angleOffset + this.currentAngleOffset
				var s = i&1 ? scale : this.dynamicScale
				var x = w + Math.sin(a)*s
				var y = h + Math.cos(a)*s
				if (i == 0)	CGContextMoveToPoint(ctx, x, y)
				else		CGContextAddLineToPoint(ctx, x, y)
			}
			if (this.isFilled)	CGContextFillPath(ctx)
			else				CGContextStrokePath(ctx)
		}
		
		- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
		{
			var touch = touches.anyObject
			this.locationStart = touch.locationInView(this)
			var x = this.locationStart.x-this.bounds.size.width/2
			var y = this.locationStart.y-this.bounds.size.height/2
			var distanceFromCenter = Math.sqrt(x*x+y*y)/(this.bounds.size.width/2)
			// Rotate when dragging from outside, Scale when dragging from inside
			this.action = distanceFromCenter > 0.7 ? 'rotating' : 'scaling'
		}
		- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
		{
			var touch = touches.anyObject
			var location = touch.locationInView(this)
			var w = this.bounds.size.width/2
			var h = this.bounds.size.height/2

			if (this.action == 'scaling')
			{
				var x = location.x-this.bounds.size.width/2
				var y = location.y-this.bounds.size.height/2
				var distanceFromCenter = Math.sqrt(x*x+y*y)///(this.bounds.size.width)
				this.dynamicScale = distanceFromCenter
			}
			else
			{
				var x0 = this.locationStart.x - w
				var y0 = this.locationStart.y - h
				var l0 = Math.sqrt(x0*x0+y0*y0); x0 /= l0, y0 /= l0
				
				var x1 = location.x - w
				var y1 = location.y - h
				var l1 = Math.sqrt(x1*x1+y1*y1); x1 /= l1, y1 /= l1
				
				this.currentAngleOffset = Math.acos(x0*x1 + y0*y1)
				this.currentAngleOffset = Math.atan2(x1, y1) - Math.atan2(x0, y0)
			}
			[this setNeedsDisplay]
		}
		- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
		{
			this.angleOffset += this.currentAngleOffset
			this.currentAngleOffset = 0
		}
	
	@end
	

