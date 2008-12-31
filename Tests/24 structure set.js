
	// Can't make it work !
	// There should be a hook when objects get a new name (eg var f = myView.frame -> myView.frame is bound to f)

/*


	var o = NSView.instance()
	log('====================================')
	o.frame.origin.x = 0
//	o.frame.origin.x = o.frame.size.width + o.frame.size.height + 13

	log('++++++++++++++++++++++++++++++++++++')
	var frame = o.frame
	frame.origin.x = 13
	log('====================================')
	if (frame.origin.x != 13)	throw 'structure set FAILED 1'
	
	if (o.frame.origin.x != 0)	throw 'structure set FAILED 2'
	o.frame.origin.x = 14
	if (o.frame.origin.x != 14)	throw 'structure set FAILED 3'
	
	var frame2 = o.frame
	frame2.origin.x = 15
	if (frame2.origin.x != 15)	throw 'structure set FAILED 4'
	

	if (o.frame.origin.x != 14)	throw 'structure set FAILED 5'

*/