

	//
	// Objective-J, JSTalk - like syntax
	//	class syntax compatibility
	//

	@implementation ObjJClassSyntax1 : NSObject
		- (int)method1:(int)a and2:(int)b
		{
			return a+b+1
		}
	@end


	@implementation ObjJClassSyntax2 : ObjJClassSyntax1
	// Right now these are just skipped.
	{
		int		var1
		float	var2
	}

		- (int)method1:(int)a and2:(int)b
		{
			return a+b+10+[super method1:a and2:b]
		}
	@end
	

	@implementation ObjJClassSyntax2 (SomeExtraMethods)
		- (id)hello
		{
			return 'hello'
		}
		- (id)world
		{
			return 'world'
		}

		// Check protocol indicator's generated encoding 
		- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item
		{
			return false
		}
		
	@end

	var o = [ObjJClassSyntax1 instance]
	
	var r = [o method1:4 and2:3]
	if (r != (4+3+1))					throw 'ObjJ compat syntax failed (1)'

	var o = [ObjJClassSyntax2 instance]
	var r = [o method1:13 and2:36]
	if (r != (13+36+1+10+13+36))		throw 'ObjJ compat syntax failed (2)'

	if ([o hello] != 'hello')			throw 'ObjJ compat syntax failed (3)'
	if ([o world] != 'world')			throw 'ObjJ compat syntax failed (4)'
	
	
	// Protocol indicator
	var protocolMethodSignature = [JSCocoa typeEncodingOfMethod:'validateUserInterfaceItem:' class:'ObjJClassSyntax2']
	if (protocolMethodSignature != 'c@:@')	throw 'ObjJ compat syntax failed (5)'

	o = null



