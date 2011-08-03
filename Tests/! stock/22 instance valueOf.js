/*


	// Alas, doesn't work.

	JSCocoaController.sharedController.evalJSFile(NSBundle.mainBundle.bundlePath + '/Contents/Resources/class.js')



	Class('MyInstanceValueOfTest < NSObject').definition = function () 
	{
	}

	log('a')
	var o1 = MyInstanceValueOfTest.instance
	log('b')
	var o2 = MyInstanceValueOfTest.instance
	log('c')

	var count = JSCocoaController.liveInstanceCount('MyInstanceValueOfTest')
	log(count)
	
	if (count != 2)	throw 'invalid MyInstanceValueOfTest instance count'


	o1 = null
	o2 = null
*/