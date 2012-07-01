
	/*
		Defines a custom C function and its associated bridgesupport
			(This one uses GLFloat, so only 'type' in bridgesupport, no 'type64')
	*/


	var c = ccc4f(1, 2, 3, 4)
	
	if (Math.round(c.r) != 1)		throw 'Manual bridgesupport failed (1)'
	if (Math.round(c.g) != 2)		throw 'Manual bridgesupport failed (2)'
	if (Math.round(c.b) != 3)		throw 'Manual bridgesupport failed (3)'
	if (Math.round(c.a) != 4)		throw 'Manual bridgesupport failed (4)'
	
	if (NSCompositeCopy1 != 123)	throw 'Manual bridgesupport failed (5)'
	if (NSCompositeCopy2 != 456)	throw 'Manual bridgesupport failed (6)'

	if (NSToolbarPrintItemIdentifier1 != 'printItemIdentifier1')		throw 'Manual bridgesupport failed (7)'
	if (NSToolbarPrintItemIdentifier2 != 'printItemIdentifier2')		throw 'Manual bridgesupport failed (8)'
