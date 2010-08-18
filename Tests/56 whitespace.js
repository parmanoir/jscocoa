

	var object = MRTestWhitespace.alloc.init.autorelease;

/*
	var linebreak = object.fetchLinebreak;

	log('Linebreak: `' + linebreak + '`');
	log('Tab: `' + object.fetchTab + '`');
	log('Four Spaces: `' + object.fetchSpaces + '`');

	if (linebreak) {
		log('linebreak evaluates as true');
	} else {
		log('linebreak evaluates as false');
	}

	log('className: ' + linebreak.className);
*/

	if (object.fetchLinebreak != '\n')		throw 'Whitespace failed (1)'
	if (object.fetchTab != '	')			throw 'Whitespace failed (2)'
	if (object.fetchSpaces != '    ')		throw 'Whitespace failed (3)'
	
	
	log('a')
	var o = NSString.stringWithString('hello')
	log('b')
	var p = NSString.stringWithString(o)
	log('c')
	var n = NSNumber.numberWithInt(123)
	log('d')
	NSApplication.sharedApplication.delegate.add1(n)
	log('e')
	log('r=' + r)
	log(o + '*')
	log(p + '*')	