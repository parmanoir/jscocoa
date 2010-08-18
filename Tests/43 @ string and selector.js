
	//
	// ObjC friendly immediates
	//

	// Defines a NSString via NSString.stringWithString
	var str = @'hello'
	if (![str isKindOfClass:NSString])	throw 'NSString immediate failed (1)'

	var str = @'hello' + ' ' + @'world'
	if (str != 'hello world')			throw 'NSString immediate failed (2)'
	

	// Syntax sugar - @selector(init) defines a raw javascript string 'init' 
	// (Conversion to selector is implicit in JSCocoa's internals)
	var sel1 = @selector(init)
	var sel2 = @selector(hello:world:)
	if (sel1 != 'init')					throw '@selector immediate failed (1)'
	if (sel2 != 'hello:world:')			throw '@selector immediate failed (2)'
	
	var sel3 = sel1 + sel2
	if (sel3 != 'inithello:world:')		throw '@selector immediate failed (3)'
	
	
	