

	log('Auf Deutsch')


	localizedStrings['BookCount'] = function (count)
									{
										if (count == 0)	return 'Keine Bücher gefunden !'
										if (count == 1)	return 'Ein Buch'
										return count + ' Bücher'
									}

