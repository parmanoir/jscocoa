
	var encodings = { 	
		 'id'			: '@'
		,'class'		: '#'
		,'selector'		: ':'
		,'char'			: 'c'
		,'uchar'		: 'C'
		,'short'		: 's'
		,'ushort'		: 'S'
		,'int'			: 'i'
		,'uint'			: 'I'
		,'long'			: 'l'
		,'ulong'		: 'L'
		,'longlong'		: 'q'
		,'ulonglong'	: 'Q'
		,'float'		: 'f'
		,'double'		: 'd'
		,'bool'			: 'B'
		,'void'			: 'v'
		,'undef'		: '?'
		,'pointer'		: '^'
		,'charpointer'	: '*'
	}
	var reverseEncodings = {}
	for (var e in encodings) reverseEncodings[encodings[e]] = e
	
	function	objc_encoding()
	{
		var encoding = encodings[arguments[0]]
		encoding += '@:'
		
		for (var i=1; i<arguments.length; i++)	
		{
			if (!(arguments[i] in encodings))	throw	'invalid encoding : ' + arguments[i]
			encoding += encodings[arguments[i]]
		}
		return	encoding
	}
