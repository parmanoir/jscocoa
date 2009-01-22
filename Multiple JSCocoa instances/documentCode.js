/*

	Code loaded in each document, each having its own global variables

*/


//log('hello from document ' + document)

	field1.stringValue = Math.round(Math.random()*100)
	field2.stringValue = Math.round(Math.random()*100)
	function	click()
	{
		var a = parseFloat(field1.stringValue)
		var b = parseFloat(field2.stringValue)
		var result = a + b
		var result = sharedAdder.add_and(a, b)
		field3.stringValue = result

		field4.stringValue = ((new Date).getTime()) + ' Added ' + field1 + ' and ' + field2 + ' to ' + field3 + '\n' + field4.stringValue
	}
	
//	log(SharedAdder)
	var sharedAdder = SharedAdder.instance()
	
	var magic = -1000
/*	
	log(jsc)
	log(__jsc__)
	log('HAS=' + ('NSObject2' in this))
	defineClass(actuallyCreateOne)
*/	