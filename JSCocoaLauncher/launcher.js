
log('hello world')
log('BUG double click cell')


	class ApplicationController < NSObject
	{
	
		- (void)awakeFromNib
		{
			log('awoke' + this.sourceList)
			this.sourceList.delegate = this
			
			var cell = ImageAndTextCell.instance()
			cell.someVar = 'hello'
			this.sourceList.tableColumns[0].dataCell = cell
			this.sourceList.expandItem(this.sourceList.itemAtRow(2))
			this.sourceList.expandItem(this.sourceList.itemAtRow(1))
			this.sourceList.expandItem(this.sourceList.itemAtRow(0))
		}
		
		- (id)sidebarItems
		{
			return	[	 { name : 'SAMPLES', isGroupItem : true
							,children : [ { name : 'Mac OS' }, { name : 'iPhone Simulator' }, { name : 'Interactive Console' } ] }
						,{ name : 'DISCUSS', isGroupItem : true
							,children : [ { name : 'Report Bug' }, { name : 'Request Feature' } ] }
						,{ name : 'VISIT', isGroupItem : true
							,children : [ { name : 'Source' }, { name : 'Users' }, { name : 'Homepage' }, { name : 'Discussion Group' } ] }
					]
		}
		
		- (BOOL)outlineView:(NSOutlineView*)outlineView isGroupItem:(id)item
		{
			return	item.representedObject.isGroupItem
		}
		
		- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
		{
//			log('select ' + item.representedObject)
			return	true
		}
		
		- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
		{
//			log('will display')
		}
		

		IBOutlet	sourceList
	}
	
	
	//
	// From Apple's SourceView
	//
	class ImageAndTextCell < NSTextFieldCell
	{
		- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
		{
			this.Super(arguments)
		}
/*	
		+ (id)copyWithZone2:(NSZone*)zone
		{
			// Outline view will make copies of the cell
			JSCocoa.upInstanceCount
			log('COPPYYING ' + '')
			return this.Super(arguments)
		}
*/
	}
	
	