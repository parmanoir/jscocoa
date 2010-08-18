


	/*

		Check struct instance via new :
		
		var p = new NSPoint
		p.x = 4.5
		
		var p2 = new CGRect

	*/

	// NSPoint zero argument instance — expecting all structure members to be created with undefined values
	var p1 = NSMakePoint(4.5, 8.2)
	
	var p2 = new NSPoint
	if (!('x' in p2))			throw	'NSPoint structure instance failed — property with undefined value not created (x)'
	if (!('y' in p2))			throw	'NSPoint structure instance failed — property with undefined value not created (y)'
	p2.x = 4.5
	p2.y = 8.2
//	log('p1=' + p1.x + ',' + p1.y);
//	log('p2=' + p2.x + ',' + p2.y);
	if (!NSEqualPoints(p1, p2))	throw	'NSPoint structure instance failed'


	// CGRect zero argument instance
	var r1 = CGRectMake(1, 2, 3, 4)
	var r2 = new CGRect
	if (!('origin'	in r2))			throw	'CGRect structure instance failed — property with undefined value not created (origin)'
	if (!('x'		in r2.origin))	throw	'CGRect structure instance failed — property with undefined value not created (origin.x)'
	if (!('y'		in r2.origin))	throw	'CGRect structure instance failed — property with undefined value not created (origin.y)'
	if (!('size'	in r2))			throw	'CGRect structure instance failed — property with undefined value not created (size)'
	if (!('width'	in r2.size))	throw	'CGRect structure instance failed — property with undefined value not created (size.width)'
	if (!('height'	in r2.size))	throw	'CGRect structure instance failed — property with undefined value not created (size.height)'

	r2.origin.x = 1
	r2.origin.y = 2
	r2.size.width = 3
	r2.size.height = 4
	
	if (!CGRectEqualToRect(r1, r2))	throw	'CGRect structure instance failed'
	
	
	// NSPoint argument instance
	var p3 = new NSPoint(4.5, 8.2)
	if (!NSEqualPoints(p1, p3))		throw	'NSPoint structure instance with arguments failed'
	
	// CGRect argument instance
	var r3 = new CGRect(1, 2, 3, 4)
	if (!CGRectEqualToRect(r1, r3))	throw	'CGRect structure instance with arguments failed'


	// This should fail : one arg missing
	var failed = false
	try	{ 
		var r4 = new CGRect(1, 2, 3) 
	} catch (e) { 
		failed = true 
	}
	if (!failed)					throw	'expected CGRect structure instance with too few arguments to fail'

	// This should fail : one arg too many
	var failed = false
	try	{
		var r5 = new CGRect(1, 2, 3, 4, 5) 
	} catch (e) { 
		failed = true 
	}
	if (!failed)					throw	'expected CGRect structure instance with too many arguments to fail'


