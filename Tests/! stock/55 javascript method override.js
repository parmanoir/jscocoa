
/*

	Use Javascript functions to override behaviour of existing ObjC objects
		(This override exists only on the JSCocoa side and lets the ObjC methods intact)

*/

	var canSet = __jsc__.canSetOnBoxedObjects
	__jsc__.canSetOnBoxedObjects = true

	var wentThrough1, wentThrough2, wentThrough3


	@implementation JavascriptMethodOverride : NSObject
	
		- (int)add:(int)a
		{
			wentThrough1 = true
			return a + 10
		}
		- (int)add:(int)a and:(int)b
		{
			wentThrough2 = true
			return a + b + 20
		}
	
	@end


	var o = JavascriptMethodOverride.instance
	o.add = function ()
	{
		wentThrough3 = true
		if (arguments.length == 1)		return this.add_(arguments[0])
		if (arguments.length == 2)		return this.add_and_(arguments[0], arguments[1])
		return null
	}
	
	
	wentThrough1 = wentThrough2 = wentThrough3 = false
	
	if (o.add_(15) != 25)											throw 'Javascript method override failed (1)'
	if (!(wentThrough1 && !wentThrough2 && !wentThrough3))			throw 'Javascript method override failed (2)'

	
	wentThrough1 = wentThrough2 = wentThrough3 = false
	
	if (o.add_and_(5, 7) != 32)										throw 'Javascript method override failed (3)'
	if (!(!wentThrough1 && wentThrough2 && !wentThrough3))			throw 'Javascript method override failed (4)'


	wentThrough1 = wentThrough2 = wentThrough3 = false
	
	if (o.add(15) != 25)											throw 'Javascript method override failed (5)'
	if (!(wentThrough1 && !wentThrough2 && wentThrough3))			throw 'Javascript method override failed (6)'


	wentThrough1 = wentThrough2 = wentThrough3 = false
	
	if (o.add(5, 7) != 32)											throw 'Javascript method override failed (7)'
	if (!(!wentThrough1 && wentThrough2 && wentThrough3))			throw 'Javascript method override failed (8)'

	o = null
	

	//
	// Test on a raw ObjC object, not a JSCocoa derived one
	//
	var wentThrough4 = false
	
	o = NSObject.instance
	o.respondsToSelector = function (sel)
	{
		wentThrough4 = true
		return this.respondsToSelector_(sel)
	}

	o.respondsToSelector('hello')
	if (!wentThrough4)												throw 'Javascript method override failed (9)'
	
	o = null
	
	__jsc__.canSetOnBoxedObjects = canSet
	
	