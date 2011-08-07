

//	log('TEST !')

	var delayedTests
	
	function	resetDelayedTests()
	{
		delayedTests = {}
	}
	function	delayedTestCount()
	{
		var l = 0
		for (var i in delayedTests) l++
		return l
	}
	
	function	delayedTestPendingCount()
	{
		var l = 0
		for (var i in delayedTests) if (delayedTests[i] == 'pending')	l++
		return l
	}
	function	delayedTestSuccessCount()
	{
		var l = 0
		for (var i in delayedTests) if (delayedTests[i])	l++
		return l
	}
	
	function	registerDelayedTest(name)
	{
		delayedTests[name] = 'pending'
	}
	
	function	completeDelayedTest(name, status)
	{
		delayedTests[name] = !!status
		log('Pending test ' + name + ' ' + (status ? 'complete' : 'FAIL'))
		if (delayedTestPendingCount() == 0)	
		{
			log('All pending tests ran, ' + delayedTestSuccessCount() + '/' + delayedTestCount() + ' successful')
			NSApplication.sharedApplication.delegate.delayedTestsRan_outof_(delayedTestSuccessCount(), delayedTestCount())
		}
	}
	
