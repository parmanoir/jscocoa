
	// Split call disabled by default since ObjJ syntax
	var useSplitCall = __jsc__.useSplitCall
	__jsc__.useSplitCall = true



	/*
	
		defineClass(..., hashOfMethods)
	
		hashOfMethods = {
			
			pureJavascriptMethod : function (a, b, c)
			{
				return ...
			}
		}
	
	*/


	Class('MyJSFunctionTest < NSObject').definition = function () 
	{
		Method('customAdd:And:').encoding('int int int').fn = function (a, b)
		{
			return a+b+this.jsAdd1(a, b)
		}
		
		JSFunction('jsAdd1').fn = function (a, b)
		{
			return a*2+b*3
		}
		
		JSFunction('jsAdd2').fn = function (a, b)
		{
			return '*' + a + '_' + b + '$'
		}
	}
	

	Class('MyJSFunctionTest2 < MyJSFunctionTest').definition = function () 
	{
		JSFunction('jsAdd3').fn = function (a, b)
		{
			return '*' + b + '_' + a + '$'
		}
	}
	
	
	var o1 = MyJSFunctionTest.instance
	
	var addResult1 = o1.custom({ add : 4, and : 5 })
	var addResult2 = o1.jsAdd2(4, 5)
//	log(addResult1)
//	log(addResult2)
	
	o1 = null
	
	if (addResult1 != 4+4*2+5+5*3)	throw 'pure js call failed (1)'
	if (addResult2 != '*4_5$')		throw 'pure js call failed (2)'

	// Test derived class
	var o2 = MyJSFunctionTest2.instance
	var addResult1 = o2.custom({ add : 4, and : 5 })
	var addResult2 = o2.jsAdd2(4, 5)
	var addResult3 = o2.jsAdd3(4, 5)

	if (addResult1 != 4+4*2+5+5*3)	throw 'pure js call failed in derived class (1)'
	if (addResult2 != '*4_5$')		throw 'pure js call failed in derived class (2)'
	if (addResult3 != '*5_4$')		throw 'pure js call failed in derived class (3)'


	__jsc__.useSplitCall = useSplitCall
