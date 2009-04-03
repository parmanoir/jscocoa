
log('hello world')


	class ApplicationController < NSObject
	{
	
		- (void)awakeFromNib
		{
			log('awoke' + this.sourceList)
			this.sourceList.delegate = this
		}
		
		- (id)sidebarItems
		{
			return	[	 { name : 'Samples', isGroupItem : true
							,children : [ { name : 'Mac OS' }, { name : 'iPhone' }, { name : 'Interactive Console' } ]
							}
						,{ name : 'Visit'
							,children : [ { name : 'Source' }, { name : 'Users' }, { name : 'Homepage' } ] }
					]
		}
		
		- (BOOL)outlineView:(NSOutlineView*)outlineView isGroupItem:(id)item
		{
			return	item.representedObject.isGroupItem
		}
		
		- (BOOL)outlineView:(NSOutlineView*)outlineView shouldSelectItem:(id)item
		{
			log('select ' + item.representedObject)
			return	true
		}
	
		IBOutlet	sourceList
	}