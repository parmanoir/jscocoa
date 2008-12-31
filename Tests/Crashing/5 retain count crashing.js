
	var autoReleasedObject = CALayer.alloc.init
	
	JSCocoaController.log('>>>>>>>>>>someKindOfObjectAllocCount=' + ApplicationController.someKindOfObjectAllocCount + ' last=' + autoReleasedObject)
	autoReleasedObject.release
