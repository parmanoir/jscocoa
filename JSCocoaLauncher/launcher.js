

/*

	forum : includ possibilité de run JSCocoa code


*/


	log('tap un letr dans la outline first responder pars TOUT les selexion !')


	JSCocoa.hazardReport

	class ApplicationController < NSObject
	{
	
		- (void)awakeFromNib
		{
			this.sourceList.delegate = this
			
			var cell = ImageAndTextCell.instance()
			this.sourceList.tableColumns[0].dataCell = cell
			
			//
			// Icons
			//
			var images = {	 'Mac' : NSImage.imageNamed('NSComputer')
							,'Console' : NSImage.imageNamed('Console')
							,'iPhoneSimulator' : NSImage.imageNamed('iPhoneSimulator') 
							,'GoogleGroups' : NSImage.imageNamed('GoogleGroups') 
							,'URL' : NSImage.imageNamed('URL') 
							}
			images['Mac'].size = new NSSize(16, 16)
			images['URL'].size = new NSSize(16, 16)
			
			//
			// Sidebar items
			//
			this.willChangeValueForKey('sidebarItems')
			this.items = [	 { name : 'SAMPLES', isGroupItem : true
							,children : [ { name : 'Mac OS', image : images['Mac'] }
										,{ name : 'iPhone Simulator', image : images['iPhoneSimulator'] }
										,{ name : 'Console', image : images['Console'] } ] }
						,{ name : 'TRADE', isGroupItem : true
							,children : [ { name : 'Download samples' }, { name : 'Upload a sample' } ] }
						,{ name : 'DISCUSS', isGroupItem : true
							,children : [ { name : 'Report Bug' }, { name : 'Request Feature' }, { name : 'Google Group', image : images['GoogleGroups'] } ] }
						,{ name : 'VISIT', isGroupItem : true
							,children : [ { name : 'Source', image : images['URL'], id : 'source' }, { name : 'Homepage', image : images['URL'], id : 'home' } ] }
					]
			this.didChangeValueForKey('sidebarItems')

			// Expand
			this.sourceList.expandItem(this.sourceList.itemAtRow(3))
			this.sourceList.expandItem(this.sourceList.itemAtRow(2))
			this.sourceList.expandItem(this.sourceList.itemAtRow(1))
			this.sourceList.expandItem(this.sourceList.itemAtRow(0))
			// Select
			this.sourceList.select({rowIndexes:NSIndexSet.indexSetWithIndex(1), byExtendingSelection:NO })
			
			
			//
			// Position window
			//
			var windowFrame = this.window.frame
			var screenFrame = NSScreen.mainScreen.visibleFrame
			this.window.setFrameOrigin(new NSPoint((screenFrame.size.width-windowFrame.size.width)/2, (screenFrame.size.height-windowFrame.size.height)*2/3))
			

			//
			// Hash of views, holding name : NSView
			//
			this.views = {}
		}
		
		- (id)sidebarItems
		{
			return	this.items
		}
		
		- (BOOL)outlineView:(NSOutlineView*)outlineView isGroupItem:(id)item
		{
			return	item.representedObject.isGroupItem
		}
		
		- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
		{
			var canSelect =	!item.representedObject.isGroupItem
			log('canSelect ' + item.representedObject.name)
			if (canSelect)	this.switchToView(item.representedObject.id)
			return	canSelect
		}
		- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item
		{
			return	NO
		}
		
		- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
		{
			return	NO
		}
		
		- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
		{
			cell.object = item.representedObject
		}
		
		js function switchToView(viewName)
		{
			log('NEW VIEW ' + viewName)
//			log('DEBUG CHECK ' + this.sidebarItems)
//			__jsc__.garbageCollect

			var view = this.views[viewName]
			if (!view)
			{
				log('asking to build ' + viewName)
				if (viewName == 'source')
				{
					var view = WebView.instance({ withFrame : NSMakeRect(200, 0, 400, 400) })
					this.window.contentView.addSubview(view)
					view.mainFrameURL = 'http://yahoo.com'
					log('built ' + view)
				}
				if (viewName == 'home')
				{
					var view = WebView.instance({ withFrame : NSMakeRect(250, 50, 400, 400) })
					this.window.contentView.addSubview(view)
					view.mainFrameURL = 'http://google.com'
					log('built ' + view)
				}
				
				if (view)	this.views[viewName] = view
			}
			
			if (this.currentView)
				this.currentView.hidden = YES
			
			if (!view)	return
			
			view.hidden = NO
			this.currentView = view
		}

		IBOutlet	sourceList
		IBOutlet	window
	}
	
	
	class SourceList < NSOutlineView
	{
		- (NSRect)frameOfOutlineCellAtRow:(NSInteger)row
		{
			return	new NSRect(0, 0, 0, 0)
		}
	}

	//
	// From Apple's SourceView
	//
	class ImageAndTextCell < NSTextFieldCell
	{
		- (id)init
		{
			var r = this.Super(arguments)
			this.font = NSFont.systemFontOfSize(NSFont.smallSystemFontSize)
			return	r
		}
		- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
		{
			var x = 0
			if (this.object.image) 
			{
				this.object.image.composite({toPoint:NSMakePoint(cellFrame.origin.x, cellFrame.origin.y+18), operation:NSCompositeSourceOver})
				x += 18
			}

			arguments[0] = new NSRect(cellFrame.origin.x+x, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height)
			this.Super(arguments)
		}
	}
	
	
	
	//
	// Custom Split View
	//
	class SplitView < NSSplitView
	{
		- (void)drawDividerInRect:(NSRect)rect
		{





			var ctx = NSGraphicsContext.currentContext.graphicsPort
//			log('ctx=' + ctx)
//return


//			log(rect)
//			log('colorSpace name=' + kCGColorSpaceGenericRGB)
			var colorSpace = CGColorSpaceCreateWithName('kCGColorSpaceGenericRGB')
//			var colorSpace = CGColorSpaceCreateWithName(nil)
//			log('colorSpace=' + colorSpace)
//return

//			NSBezierPath.bezierPathWithRect(rect).fill

//			var buffer = JSCocoaMemoryBuffer.bufferWithTypes('ffffffff')
			var components = new memoryBuffer('ffffffff')
			components[0] = 1
			components[1] = 0
			components[2] = 0
			components[3] = 0.9
			components[4] = 0
			components[5] = 1
			components[6] = 0
			components[7] = 1

			var locations = new memoryBuffer('ff')
			locations[0] = 0
			locations[1] = 1
			
			var backgroundGradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, 2)
//			log('backgroundGradient=' + backgroundGradient)

			var ctx = NSGraphicsContext.currentContext.graphicsPort
//			log('ctx=' + ctx)


var options = kCGGradientDrawsBeforeStartLocation + kCGGradientDrawsAfterEndLocation

	CGContextDrawRadialGradient(ctx, backgroundGradient, 
								CGPointMake(0, 0), 200,
								CGPointMake(100, 100), 100,
								0);
//CGContextDrawLinearGradient(ctx, backgroundGradient, new CGPoint(0, 0), new CGPoint(200, 200), options)
/*
	CGFloat components[8] = {	[c1 redComponent], [c1 greenComponent], [c1 blueComponent], 1.0,
								[c2 redComponent], [c2 greenComponent], [c2 blueComponent], 1.0,
								};
	CGColorSpaceRef colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	CGGradientRef backgroundGradient = CGGradientCreateWithColorComponents(colorspace, components, locations, num_locations);
	CGColorSpaceRelease(colorspace);

	[[NSColor whiteColor] setFill];
	NSBezierPath* path = [NSBezierPath bezierPathWithRect:rect];
	[path fill];

	float width = [self frame].size.width;
	float height = [self frame].size.height;

	CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort]; 	
	CGContextScaleCTM(ctx, 1, roundness);

	float w = width/2;
	float y1 = height/roundness;
	float y2 = 	y2 = 0-w;

	CGContextDrawRadialGradient(ctx, backgroundGradient, 
								CGPointMake(width/2, y1), w,
								CGPointMake(width/2, y2), w,
								0);

	CGGradientRelease(backgroundGradient);
*/

			this.Super(arguments)

	CGGradientRelease(backgroundGradient)


		}
	}
	
	