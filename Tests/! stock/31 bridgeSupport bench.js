


	function	getTickCount()	{ return (new Date).getTime() }
	
	var t1 = getTickCount()

//log('***********************')
	var a = 1
	var b = 2
	var c = 3
	var r = 0
	var iterationCount = 10000000
	var iterationCount = 10
	for (var i=0; i<iterationCount; i++)
	{
		r += a
		r += b
		r += c
	}
	var t2 = getTickCount()
//log('***********************')

//	log('time=' + (t2-t1) + ' res=' + r + ' running in JSCocoa=' + ('NSWorkspace' in this))
