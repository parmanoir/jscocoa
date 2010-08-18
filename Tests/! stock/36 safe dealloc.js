
	//
	// Safe dealloc
	//	Allow -(void)dealloc to be overloaded. As dealloc is called during JS GC, no js code can be called then.
	//	Overloaded dealloc will be called in the next run loop cycle.
	//



	// Split call disabled by default since ObjJ syntax
	var useSplitCall = __jsc__.useSplitCall
	__jsc__.useSplitCall = true


	var safe1Called = 0
	var safe2Called = 0
	var	bindingCleaned

	//
	// Safe dealloc test completion
	//	AT THIS POINT OBJECTS WILL STILL BE ALIVE, as JavscriptCore is still retaining the JSCocoaPrivateObjects holding them.
	//	They will be deallocated on next GC cycle.
	//
	function	checkEndTest36()
	{
		if (safe1Called == 2 && safe2Called == 1 && bindingCleaned)
		{
			completeDelayedTest('36 safe dealloc', true)
			
//			JSCocoa.logInstanceStats
//			__jsc__.garbageCollect
//			JSCocoa.logInstanceStats
		}
	}
	

	// This js dealloc method will be called in the next run loop cycle, then the ObjC release method, deallocating the object
	class	SafeDeallocTest < NSObject
	{
		- (void)dealloc
		{
//			log('safe dealloc called')
			this.Super(arguments)
			
			safe1Called++
			
			checkEndTest36()
		}
	}
	
	// js deallocs are standard methods and can be derived.
	class	SafeDeallocTest2 < SafeDeallocTest
	{
		- (void)dealloc
		{
//			log('SECOND safe dealloc called')
			this.Super(arguments)
	
			safe2Called++
		}
	}
	

	// Test safe dealloc
	var o1 = SafeDeallocTest.instance
	var o2 = SafeDeallocTest2.instance
	o1.safeDealloc = o2.safeDealloc = true
	
	// Need to remove this : needed to put __jsc__ ivar in instances
//	o1.blaaaaaaaaaaah = 'hello'
//	o2.blaaaaaaaaaaah = 'hello'

	o1 = null
	o2 = null
	



	// Test binding dealloc
	
	// Bindinds safe dealloc test
	class	BindingsSafeDeallocSource < NSObject
	{
		Key sourceValue
	}

	class	BindingsSafeDeallocTarget < NSObject
	{
		- (void)dealloc
		{
//			log('exposedBindings=' + this.exposedBindings)
//			log('dealloc! ' + this)
			this.unbind('targetValue')
			bindingCleaned = true
			checkEndTest36()
		}
		Key targetValue
	}

	if (!('bindingsAlreadyTested2' in this) && !NSApplication.sharedApplication.delegate.bindingsAlreadyTested2)
	{
		var oSource = BindingsSafeDeallocSource.instance
		var oTarget = BindingsSafeDeallocTarget.instance
//		log('oSource=' + oSource + ' rc=' + oSource.retainCount)
//		log('oTarget=' + oTarget + ' rc=' + oTarget.retainCount)


//		- (void)bind:(NSString *)binding toObject:(id)observable withKeyPath:(NSString *)keyPath options:(NSDictionary *)options;    // placeholders and value transformers are specified in options dictionary


		oTarget.bind_toObject_withKeyPath_options('targetValue', oSource, 'sourceValue', null)
		oSource.set({ value : 'hello', forKey : 'sourceValue' })
//		log('t=' + oTarget.targetValue)
		if (oTarget.targetValue != 'hello')		throw '(safe dealloc) invalid binding (1)'

		oSource.set({ value : 'world', forKey : 'sourceValue' })
//		log('t=' + oTarget.targetValue)
		if (oTarget.targetValue != 'world')		throw '(safe dealloc) invalid binding (2)'
		
		oSource = null
		oTarget = null
	}
	bindingsAlreadyTested2 = true
	NSApplication.sharedApplication.delegate.bindingsAlreadyTested2 = true
	
	// Force GC to trigger safe dealloc
	__jsc__.garbageCollect



	registerDelayedTest('36 safe dealloc')



// careful of context being deallocated : context need to be deallocated AFTER safe dealloc is called
// ^disabled for now. Any safe dealloc will have to be called before JSCocoaController is deallocated


//	throw ('bindings auto remove')


	__jsc__.useSplitCall = useSplitCall
