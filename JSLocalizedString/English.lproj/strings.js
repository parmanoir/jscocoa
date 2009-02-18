

	log('In English')
	
/*
	// Register a hash
	var strings = { 'BookCount' : 'hello' }
	registerLocalizedStrings(strings)
*/	

	// Register in main hash
	localizedStrings['BookCount'] = 'Book Count'

	localizedStrings['BookCount'] = function (count)
									{
										if (count == 0)	return 'No books found !'
										if (count == 1)	return 'One book'
										return count + ' books'
									}

