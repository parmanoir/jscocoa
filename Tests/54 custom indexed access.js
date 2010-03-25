
/*

	Use Javascript bracket notation to get and set objects, whether as arrays or dictionaries.
	
		var a = customIndexAccess[i].x
		customIndexAccess[i].x = 123
		
	Add get and set methods in a class to have it behave like an array or a hash in Javascript.

		Behave like an array
			get		- (id)objectAtIndex:(int)index
			set		- (void)replaceObjectAtIndex:(int)index withObject:(id)anObject
			length	- (int)count
			
			Then use object[index] to get and set.

		Behave like a dictionary
			get		- (id)objectForKey:(NSString*)key
			set		- (void)setObject:(id)anObject forKey:(id)aKey
			
			Then use object[key] or object.key to get and set.

*/
	

	var globalObject
	var globalIndex

	@implementation CustomIndexedAccess : NSObject
	
		- (id)objectAtIndex:(int)index
		{
			if (index == 0)	return 'Hello'
			if (index == 1)	return 'World'
			if (index == 2)	return 'Test'
		}
		- (int)count
		{
			return 3
		}
		
		- (void)replaceObjectAtIndex:(int)index withObject:(id)anObject
		{
			globalIndex		= index
			globalObject	= anObject
//			log('replaceObjectAtIndex=' + index + ' withObject=' + anObject)
		}
	
	@end

	@implementation CustomKeyedAccess : NSObject
	
		- (id)objectForKey:(NSString*)key
		{
			if (key == 'first')		return 'Test'
			if (key == 'second')	return 'Bonjour'
			if (key == 'third')		return 'Monde'
		}
		
		- (void)setObject:(id)anObject forKey:(id)aKey
		{
			globalIndex		= aKey
			globalObject	= anObject
//			log('setObject=' + anObject + ' forKey=' + aKey)
		}
	
	@end

	
	var o = [CustomIndexedAccess instance]

	if (o[0] != 'Hello')									throw 'Custom indexed access failed (1)'
	if (o[1] != 'World')									throw 'Custom indexed access failed (2)'
	if (o[2] != 'Test')										throw 'Custom indexed access failed (3)'
	if (o.length != 3)										throw 'Custom indexed access failed (4)'
	
	o[0] = 'prim'
	if (globalIndex != 0 && globalIndex != 'prim')			throw 'Custom indexed access failed (5)'
	o[1] = 'prox'
	if (globalIndex != 1 && globalIndex != 'prox')			throw 'Custom indexed access failed (6)'
	o[2] = 'dern'
	if (globalIndex != 2 && globalIndex != 'dern')			throw 'Custom indexed access failed (7)'


	var o = [CustomKeyedAccess instance]
	if (o['first']	!= 'Test')								throw 'Custom indexed access failed (8)'
	if (o['second']	!= 'Bonjour')							throw 'Custom indexed access failed (9)'
	if (o['third']	!= 'Monde')								throw 'Custom indexed access failed (10)'
	
	o['first'] = 'prim'
	if (globalIndex != 'first' && globalIndex != 'prim')	throw 'Custom indexed access failed (11)'
	o['second'] = 'prox'
	if (globalIndex != 'second' && globalIndex != 'prox')	throw 'Custom indexed access failed (12)'
	o['third'] = 'dern'
	if (globalIndex != 'third' && globalIndex != 'dern')	throw 'Custom indexed access failed (13)'
	
	
	o	= null
	globalIndex		= null
	globalObject	= null




