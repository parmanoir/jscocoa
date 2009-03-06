
//	JSCocoaController.sharedController.evalJSFile(NSBundle.mainBundle.bundlePath + '/Contents/Resources/class.js')



	/*
		Use struct as method args
		
		method('float', 'struct:rect', 'float') returns rect

	*/



	defineClass('StructureArgsTester < NSObject', 
	{
		'testWithX:struct:Y:' :
						['struct NSPoint', 'float', 'struct NSPoint', 'float', function (x, rect, y)
						{
							var rect = NSMakePoint(rect.x+x, rect.y+y)
							return rect
						}]
	})
	
	var o = StructureArgsTester.instance()
	
	var r = o.testWith({x:1.23, struct:NSMakePoint(10, 20), y:4.56})
	
	if (Math.abs( (10+1.23) - r.x ) > 0.001)	throw 'structure args failed (1)'
	if (Math.abs( (20+4.56) - r.y ) > 0.001)	throw 'structure args failed (2)'
	
//	JSCocoaController.log('x=' + r.x + ' y=' + r.y)

	o = null

