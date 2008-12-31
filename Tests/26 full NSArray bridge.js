




	defineClass('ArrayDictBridgeTest < NSObject', 
	{
		'callWithArray:' :
						['void', 'id', function (o)
						{
							if (o.count != 4)				throw 'NSArray bridge failed (1)'
							if (o[0] != 'a')				throw 'NSArray bridge failed (2)'
							if (o[1] != 'b')				throw 'NSArray bridge failed (3)'
							if (o[2] != 7.89)				throw 'NSArray bridge failed (4)'
							if (o[3] != 'c')				throw 'NSArray bridge failed (5)'
							if (o[3].valueOf() != o.objectAtIndex(3).valueOf())	throw 'NSArray bridge failed (6)'
						}]
		,'callWithDict:' :
						['void', 'id', function (o)
						{
							if (o.allKeys.count != 2)		throw 'NSArray bridge failed (7)'
							if (o.hello != 'world')			throw 'NSArray bridge failed (8)'
							if (o['hello'] != 'world')		throw 'NSArray bridge failed (9)'
							if (o.count != 7.89)			throw 'NSArray bridge failed (10)'
						}]
		,'callWithArray2:' :
						['void', 'id', function (o)
						{
							if (o[2].hello != 'world')		throw 'NSArray bridge failed (11)'
							if (o[2].c[1] != 'b')			throw 'NSArray bridge failed (12)'
						}]
		,'callWithDict2:' :
						['void', 'id', function (o)
						{
							if (o.hello != 'world')			throw 'NSArray bridge failed (13)'
							if (o.count != 7.89)			throw 'NSArray bridge failed (14)'
							if (o.ar[0] != 4)				throw 'NSArray bridge failed (15)'
							if (o.ar[1] != 5)				throw 'NSArray bridge failed (16)'
							if (o.ar[2] != 6)				throw 'NSArray bridge failed (17)'
							if (o.ar[3].bonjour != 'monde')	throw 'NSArray bridge failed (18)'
							if (o.ar[3].parts[0] != 'a')	throw 'NSArray bridge failed (19)'
							if (o.ar[3].parts[1] != 'b')	throw 'NSArray bridge failed (20)'
							if (o.ar[3].parts[2].p != 'g')	throw 'NSArray bridge failed (21)'
							if (o.ar[3].parts[3] != 'c')	throw 'NSArray bridge failed (22)'
							if (o.ar[4] != 7)				throw 'NSArray bridge failed (23)'
//							log(o)
						}]
	})

	var o = ArrayDictBridgeTest.instance()
	
	o.callWithArray(['a', 'b', 7.89, 'c'])
	o.callWithDict({ hello : 'world', count : 7.89 })

	o.callWithArray2(['a', 'b', { hello : 'world', c : ['a', 'b', 'c'] }, 'c'])
	o.callWithDict2({ hello : 'world', count : 7.89, ar : [4, 5, 6, { bonjour : 'monde', parts : ['a', 'b', { p : 'g' }, 'c' ] }, 7] })


	o = null




/*


	objcInstance.blah = ['a', 'b', 'c']
	
	objcInstance.blah2 = ['a', ['b', 'c', 'd'], 'e']


	objcInstance.dict = { hello : 'world', { a : 'b', c : 'd' }, blah : 'hop' }
	
	
	objcInstance.a = ['a', { msg1 : 'hello', msg2 : 'world' }, 45]
	objcInstance.b = { a1 : 'hello', a2 : [4, 5, { hello : 'world' }, 6], a3 : 'bonjour' }
*/

	
//	log('hello')