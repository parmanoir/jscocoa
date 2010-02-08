
	//
	// obj.key @= value
	//	-> obj.setValue_forKey_(value, 'key')
	//
	// Lots of check because op rewriting must account for comments, parens, newlines ...
	//

	var key, value

	@implementation SetValueOpTester : NSObject
	
		- (void)setValue:(id)v forKey:(NSString *)k
		{
			key = k
			value = v
//			log(key + '=' + value)
		}
	
	@end


	var o = [SetValueOpTester instance]
	o.key @= 123
	
	if (key != 'key' && value != 123)			throw '@= failed (1)'


	o.value1 @= ((((2+2))))
	if (key != 'value1' && value != 4)			throw '@= failed (1)'
	o.value1 @= ((((2+2 /* last comment to check */ ))))
	if (key != 'value1' && value != 4)			throw '@= failed (1)'
	o.value1 @= ((((2+2 /* last comment to check */
	))))
	if (key != 'value1' && value != 4)			throw '@= failed (1)'
	o.value1 @= (((((((((((((((((((((((((((((((((((((((((((((((((((((((((2+2)))))))))))))))))))))))))))))))))))))))))))))))))))))))))
	if (key != 'value1' && value != 4)			throw '@= failed (1)'


	o. /* comment */ valueA @= 'BBB'
	if (key != 'valueA' && value != 'BBB')			throw '@= failed (1)'
	o. /* comment */ valueA /* aeaz */ @= 'BBB'
	if (key != 'valueA' && value != 'BBB')			throw '@= failed (1)'
	o. valueA /* aeaz */ @= 'BBB'
	if (key != 'valueA' && value != 'BBB')			throw '@= failed (1)'
	o. /* comment */ /* eza */ valueA /* aeaz */ /* eza */ @= 'BBB'
	if (key != 'valueA' && value != 'BBB')			throw '@= failed (1)'

	var a = 7
	o.value1 @= 1 + ((((3+a)))) + 4*(a)
	if (key != 'value1' && value != (1 + ((((3+a)))) + 4*(a)))			throw '@= failed (1)'

	o[ /* comment */ 'valueA'] @= 'BBB'
	if (key != 'valueA' && value != 'BBB')			throw '@= failed (1)'
	o[ 'valueA' /* comment */ ] @= 'BBB'
	if (key != 'valueA' && value != 'BBB')			throw '@= failed (1)'
	o[ /* comment */ 'va' + function() { return 'lu' }() + /* hep */ 'eA'] @= 'BBB'
	if (key != 'valueA' && value != 'BBB')			throw '@= failed (1)'
	
	
//	[[NSPrefset2 blah] doThisAndThatWith1:'hello2'+3+[a b] and2:'world'+[z a:1 b:[k d2] c:3]]['value3'] /* ho */ @= /* hai */ 'hello3' + 'world' + 3/5
//	[[NSPrefset2 blah] doThisAndThatWith1:'hello2'+3+[a b] and2:'world'+[z a:1 b:[k d2] c:3]]['value3' + [a b][5]] /* ho */ @= /* hai */ 'hello3' + 'world' + 3/5
	

	o = null
	
