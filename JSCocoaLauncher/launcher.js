

/*

	forum : includ possibilité de run JSCocoa code


*/


	JSCocoa.hazardReport

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
			
			//
			// Gradient header
			//
/*			
			var headerCell = GradientTableHeaderCell.instance()
//			header
			var columns = this.jscocoaItemsList.tableColumns
//			for (var i=0; i<columns.length; i++)	columns[i].headerCell = headerCell
			columns[0].headerCell = headerCell
			columns[1].headerCell = headerCell
*/			

				var query = NSMetadataQuery.instance()
//				var descriptors = NSArray.arrayWithObject(NSSortDescriptor.instance({withKey:'kMDItemFSName', ascending:true}))
//				query.setSortDescriptors(descriptors)
				
				
				NSNotificationCenter.defaultCenter.add({observer:this, selector:'notified:', name:null, object:query})
				
				
//				mdfind "(kMDItemDisplayName = 'jscocoa*'cdw) && (kMDItemFSName = '*.jscocoa'c)"
//				query.setPredicate(NSPredicate.predicateWithFormat("(kMDItemFSName like [cd]'*\.jscocoa')"))
//				query.setPredicate(NSPredicate.predicateWithFormat("(kMDItemDisplayName like[cdw] '*jscocoa*') and (kMDItemFSName like[c] \"*\.jscocoa\")"))
//				query.setPredicate(NSPredicate.predicateWithFormat("(kMDItemFSName like[cdw] '*jscocoa*')"))
				query.setPredicate(NSPredicate.predicateWithFormat("(kMDItemDisplayName like '*\.jscocoa')"))
//				query.startQuery
				this.query = query
//				log('QUERY========' + query)
				

			//
			// Set ourselves as jscocoa items list delegate
			//
			this.jscocoaItemsList.delegate = this
		}
		- (void)notified:(id)n
		{
			log('NOTIFIED' + n.object.results.length)
			if (n.object.results.length)	log(n.object.results[0].attributes)
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
//	log('selectedObject=' + this.jscocoaItemsFromSpotlight[row].valueForKey('kMDItemFSName'))
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
		
		IBOutlet	listSelection1
	}
	
	class	DetailSourceView < NSView
	{
		- (void)setDetail:(id)detail
		{
			log('detail=' + detail)
		}
		- (id)detail
		{
		}
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
/*	
	class GradientTableHeaderCell < NSTableHeaderCell
	{
		- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
		{
//			log('DRAW ' + this.stringValue)
			this.Super(arguments)
//return
			var color1 = NSColor.colorWithDevice({ white : 1, alpha : 1 })
			var color2 = NSColor.colorWithDevice({ white : 0.85, alpha : 1 })
			var gradient = NSGradient.instance({withStartingColor : color1, endingColor : color2 })
			gradient.drawIn({rect : cellFrame, angle : 90})
		}
	}
	
	class GradientTableColumn < NSTableColumn
	{
		- (void)setHeaderCell:(NSCell *)cell
		{
			log('HELLO********************')
		}
		- (id)headerCell
		{
			var r = this.Super(arguments)
			log('CELL=' + r)
			log('CELL NAME=' + r.stringValue)
			log('JUST SET IT AT START')
//			return r
			return	NSTableHeaderCell.alloc.init
		}
	}
*/	

	class	NSTableHeaderCell
	{
		Swizzle- (void)adrawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
		{
			log('this=' + this)
			log('target=' + this.target)
			log('representedObject=' + this.representedObject)
			log('objectValue=' + this.objectValue)
//			this.Original(arguments)
			log('draw')
			log('column=' + controlView)
			if (controlView.isKindOfClass(NSTableHeaderView))
			{
				var columnIndex = controlView.columnAtPoint(cellFrame.origin)
				log('column=' + columnIndex)
				var table = controlView.tableView
				log('table=' + table)
				var column = table.tableColumns[columnIndex]
				log('column=' + column)
				log('type=' + this.type)

//			return

			}
			this.Original(arguments)
			return
		
//			this.drawsBackground = NO
//			this.Original(arguments)
//			log('DRAW ' + this.stringValue)
//			this.Super(arguments)
//			NSColor.redColor.set
//			NSBezierPath.bezierPathWithRect(cellFrame).fill
//return
			var color1 = NSColor.colorWithDevice({ white : 1, alpha : 1 })
			var color2 = NSColor.colorWithDevice({ white : 0.85, alpha : 1 })
			var gradient = NSGradient.instance({withStartingColor : color1, endingColor : color2 })
			gradient.drawIn({rect : cellFrame, angle : 90})
			
			if (!this.stringValue)	return
			cellFrame.origin.y = 1
			cellFrame.origin.x = cellFrame.origin.x+2
			this.stringValue.draw({ inRect : cellFrame, withAttributes : { NSFont : this.font } })
		}
		- (void)drawSortIndicatorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView ascending:(BOOL)ascending priority:(NSInteger)priority
		{
			log('**********HEP ' + ascending + ' p=' + priority)
			this.Original(arguments)
			return
		}

		
		- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
		{
			log('AHIGHLIGHT>>>>>>>')
			return
		}
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
			log('INTERIOR>>>>>>>')
}

Swizzle- (void)ahighlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView
{

//	log('highlight=' + flag)
//	log('background color=' + this.backgroundColor)
//	log('font=' + this.font)
//	log('isHighlighted=' + this.isHighlighted)

	log(this + 'h=' + flag + ' h2=' + this.isHighlighted + ' view=' + this.controlView)
//	this.Original(arguments)
}

	}
	
	//
	// Custom Split View
	//
	class SplitView < NSSplitView
	{
		- (void)drawDividerInRect:(NSRect)rect
		{
			var color1 = NSColor.colorWithDevice({ white : 1, alpha : 1 })
			var color2 = NSColor.colorWithDevice({ white : 0.85, alpha : 1 })
			var gradient = NSGradient.instance({withStartingColor : color1, endingColor : color2 })
			gradient.drawIn({rect : rect, angle : 90})
			
			NSColor.colorWithDevice({ red : 0, green : 0, blue : 0, alpha : 0.4 }).set
			NSBezierPath.bezierPathWithRect(new NSRect(rect.origin.x, rect.origin.y, rect.size.width, 1)).fill
			NSBezierPath.bezierPathWithRect(new NSRect(rect.origin.x, rect.origin.y+rect.size.height-1, rect.size.width, 1)).fill
			
			this.Super(arguments)
		}
	}
	
	
	//
	// 
	//
	log('un custom drawing.js, ou un list de tout les methods custom draw')
	log('reload this file at runtime to change appearance')
	
	log('swizzle scrollbar draw')
	
	
	function	mouseDown(event)
	{
		log('HELLLO')
		return this.Original(arguments)
	}
	


	class NSButtonCell
	{
		Swizzle- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView*)controlView
		{
			this.Original(arguments)
			NSBezierPath.bezierPathWithOvalInRect(frame).stroke
		}
	}
	


//breaking lines by truncation
//http://gemma.apple.com/documentation/Cocoa/Conceptual/Rulers/Tasks/TruncatingStrings.html
