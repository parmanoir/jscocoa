

/*

	forum : includ possibilité de run JSCocoa code


*/

	JSCocoa.hazardReport
	
	var a = NSString.stringWithString('a%a')
	a = a.stringByAddingPercentEscapesUsingEncoding(NSASCIIStringEncoding)
	log('=' + a)

	class ApplicationController < NSObject
	{
	
		- (void)awakeFromNib
		{
			this.sidebarItemsList.delegate = this
			
			var cell = ImageAndTextCell.instance()
			this.sidebarItemsList.tableColumns[0].dataCell = cell
			
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
			this.sidebarItemsList.expandItem(this.sidebarItemsList.itemAtRow(3))
			this.sidebarItemsList.expandItem(this.sidebarItemsList.itemAtRow(2))
			this.sidebarItemsList.expandItem(this.sidebarItemsList.itemAtRow(1))
			this.sidebarItemsList.expandItem(this.sidebarItemsList.itemAtRow(0))
			// Select
			this.sidebarItemsList.select({rowIndexes:NSIndexSet.indexSetWithIndex(1), byExtendingSelection:NO })
			
			
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
			
				var query = NSMetadataQuery.instance()
//				var descriptors = NSArray.arrayWithObject(NSSortDescriptor.instance({withKey:'kMDItemFSName', ascending:true}))
//				query.setSortDescriptors(descriptors)
				
				
				NSNotificationCenter.defaultCenter.add({observer:this, selector:'notified:', name:null, object:query})
				
				
//				mdfind "(kMDItemDisplayName = 'jscocoa*'cdw) && (kMDItemFSName = '*.jscocoa'c)"
//				query.setPredicate(NSPredicate.predicateWithFormat("(kMDItemFSName like [cd]'*\.jscocoa')"))
//				query.setPredicate(NSPredicate.predicateWithFormat("(kMDItemDisplayName like[cdw] '*jscocoa*') and (kMDItemFSName like[c] \"*\.jscocoa\")"))
//				query.setPredicate(NSPredicate.predicateWithFormat("(kMDItemFSName like[cdw] '*jscocoa*')"))
				query.setPredicate(NSPredicate.predicateWithFormat("(kMDItemDisplayName like '*\.jscocoa')"))
				query.startQuery
				this.query = query
//				log('QUERY========' + query)
				

			//
			// Set ourselves as jscocoa items list delegate
			//
			this.jscocoaItemsList.delegate = this
			
			//
			// Load source code view
			//
			this.jscocoaSourceCodeView.mainFrameURL = (NSBundle.mainBundle.pathFor({ resource : 'source code view', ofType : 'html' }))
		}
		- (void)notified:(id)n
		{
//			log('NOTIFIED' + n.object.results.length)
//			if (n.object.results.length)	log(n.object.results[0].attributes)
			this.willChangeValueForKey('jscocoaItems')
			this.jscocoaItemsFromSpotlight = n.object.results
			this.didChangeValueForKey('jscocoaItems')
		}
		
//		valueForUndefinedKey
//		NSMetadataItem
		
		- (id)sidebarItems
		{
			return	this.items
		}
		- (id)jscocoaItems
		{
			return	this.jscocoaItemsFromSpotlight
//			return [ { name : 'Blah.jscocoa' }, { name : 'Hopla yougla' } ]
		}
		
		- (BOOL)outlineView:(NSOutlineView*)outlineView isGroupItem:(id)item
		{
			return	item.representedObject.isGroupItem
		}
		
		- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
		{
			this.selectedItem = null
			var canSelect =	!item.representedObject.isGroupItem
			if (canSelect) this.selectedItem = item
//			log('canSelect ' + item.representedObject.name)
//			if (canSelect)	this.switchToView(item.representedObject.id)
			return	canSelect
		}
		- (void)outlineViewSelectionDidChange:(NSNotification *)notification
		{
//			log(notification.object + '!!!!!!!!!!')
//			return
			if (!this.selectedItem)	return
			this.switchToView(this.selectedItem.representedObject.id)
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
		
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
//	log('tableViewSelectionDidChange + ' + notification.object)
	if (!this.jscocoaItemsFromSpotlight)	return
	var row = notification.object.selectedRow
//	log('selectedIndex=' + row)
	var item = this.jscocoaItemsFromSpotlight[row]
	log('selectedObject=' + item.valueForKey('kMDItemFSName'))
	log('selectedObject=' + item.valueForKey('kMDItemPath'))
}
/*
- (BOOL)selectionShouldChangeInTableView:(NSTableView *)tableView
{
	log('selectionShouldChangeInTableView')
	return	YES
}
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
	log('tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row')
	return	YES
}
- (BOOL)tableView:(NSTableView *)tableView shouldSelectTableColumn:(NSTableColumn *)tableColumn
{
	log('tableView:(NSTableView *)tableView shouldSelectTableColumn:(NSTableColumn *)tableColumn')
	return	YES;
}
*/

		
		
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
					log('view=' + view)
					this.window.contentView.addSubview(view)
					// Breaks on Debugger() — adobe 10 ?
					view.mainFrameURL = 'http://yahoo.com'
					view.mainFrameURL = 'http://reddit.com'
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

		IBOutlet	sidebarItemsList
		IBOutlet	jscocoaItemsList
		IBOutlet	window


		IBOutlet	jscocoaSourceCodeView
	}
	

	//
	// Sidebar items source list
	//
	class SourceList < NSOutlineView
	{
		// Don't display disclosure triangle
		- (NSRect)frameOfOutlineCellAtRow:(NSInteger)row
		{
			return	new NSRect(0, 0, 0, 0)
		}
	}

	//
	// Sidebar items source list cell
	//	From Apple's SourceView
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
	class NSSplitView
	{
		Swizzle- (void)drawDividerInRect:(NSRect)rect
		{
			// Draw gradient
			var color1 = NSColor.colorWithDevice({ white : 1, alpha : 1 })
			var color2 = NSColor.colorWithDevice({ white : 0.85, alpha : 1 })
			var gradient = NSGradient.instance({withStartingColor : color1, endingColor : color2 })
			gradient.drawIn({rect : rect, angle : 90})
			
			// Draw top and bottom lines
			NSColor.colorWithDevice({ red : 0, green : 0, blue : 0, alpha : 0.4 }).set
			NSBezierPath.bezierPathWithRect(new NSRect(rect.origin.x, rect.origin.y, rect.size.width, 1)).fill
			NSBezierPath.bezierPathWithRect(new NSRect(rect.origin.x, rect.origin.y+rect.size.height-1, rect.size.width, 1)).fill
			
			// Call original method to draw know
			this.Original(arguments)
		}
	}
