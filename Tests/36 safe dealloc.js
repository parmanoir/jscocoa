


	var safe1Called = 0
	var safe2Called = 0
	class	SafeDeallocTest < NSObject
	{
		- (void)dealloc
		{
//			log('safe dealloc called')
			this.Super(arguments)
			
			safe1Called++
			
			if (safe1Called == 2 && safe2Called == 1) completeDelayedTest('36 safe dealloc', true)
		}
	}
	
	class	SafeDeallocTest2 < SafeDeallocTest
	{
		- (void)dealloc
		{
//			log('SECOND safe dealloc called')
			this.Super(arguments)
	
			safe2Called++
		}
	}
	
	class	BlahBlah < NSObject
	{
		- (void)dealloc
		{
		}
	}
	
	var o1 = SafeDeallocTest.instance()
	var o2 = SafeDeallocTest2.instance()
	
	// Need to remove this : needed to put __jsc__ ivar in instances
	o1.blaaaaaaaaaaah = 'hello'
	o2.blaaaaaaaaaaah = 'hello'


	var o3 = BlahBlah.instance()
	o3.someVar = 'hello'

	o1 = null
	o2 = null
	o3 = null
	__jsc__.garbageCollect
	
	
	// Need to support derived classes !


	registerDelayedTest('36 safe dealloc')



// careful of context being deallocated : context need to be deallocated AFTER safe dealloc is called
// ^disabled for now. Any safe dealloc will have to be called before JSCocoaController is deallocated




	throw ('CHECK RETAIN COUNT + REMOVE DUMMY VARS + bindings auto remove')
