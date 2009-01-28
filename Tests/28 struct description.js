

	/*
		
		log(new NSMakePoint(3, 4))
		-> prints a readable description of the struct

	*/


	var point = NSMakePoint(12, 27)
	if (point.valueOf() != '<NSPoint {x:12, y:27}>')										throw 'struct description failed (1)'
	
	var rect = NSMakeRect(1, 5, 8, 59483)
	if (rect.valueOf() != '<NSRect {origin:{x:1, y:5}, size:{width:8, height:59483}}>')		throw 'struct description failed (2)'

//	log('point=' + point)
//	log('rect=' + rect)
