

	//
	// Exploring the runtime !
	//



	//
	// Class list
	//
	
	// All classes defined in the runtime. Right now this returns class names, not classes themselves
//	log('rootClasses=' + JSCocoa.rootclasses)
	// All root classes (NSObject, NSProxy)
//	log('classes=' + JSCocoa.classes)


	
	//
	// Derivation information
	//
	
	// Returns an array containing all superclasses and this class : NSObject, NSResponder, NSView, NSControl, NSButton
//	log('NSButton derivation path=' + NSButton.__derivationPath)
	// Returns the size of derivation path -1 (Root classes have level 0)
//	log('NSButton derivation level=' + NSButton.__derivationLevel)



	//
	// Which frameworks defines the class ?
	//

	// Path to framework defining the class
//	log('framework defining NSView=' + NSView.__classImage)


	
	//
	// Methods
	//

	// Own methods : returns an array containing the methods defined by this class level
	//	name
	//	encoding
	//	type (instance|class)
	//	class
	//	framework (path to lib defining the method implementation)
//	log('NSView.ownMethods=' + NSView.__ownMethods)

	// Methods : returns an array containing all methods defined in this class
//	log('NSView.methods=' + NSView.__methods)
//	log('CALayer.methods=' + CALayer.__methods)

//	log('NSBlock.subclassTree=\n' + NSBlock.__subclassTree)
//	log('NSBlock.ownMethods=' + NSBlock.__ownMethods)
//	log('__NSGlobalBlock__.ownMethods=' + __NSGlobalBlock__.__ownMethods)
//	log('NSMutableArray.ownMethods=' + NSMutableArray.__ownMethods)



	//
	// Subclasses
	//
//	log('NSView.subclasses=' + NSView.__subclasses)

	// Display subclasses as a tree
//	log('NSView.subclassTree=\n' + NSView.__subclassTree)

//	log('NSButton.subclassTree=\n' + NSButton.__subclassTree)

//	log('NSObject.subclassTree=\n' + NSObject.__subclassTree)
	


	//
	// ivars
	//	Just like methods, use
	//	ivars to get ALL ivars in the class, including ivars from all superclasses
	//	ownIvars to get ivars from this class only
	//
//	log('NSView.ivars=' + NSView.__ivars)
//	log('NSResponder.ivars=' + NSResponder.__ivars)



	//
	// Properties
	//
//	log('CALayer.properties=' + CALayer.__properties)
//	log('CATextLayer.properties=' + CATextLayer.__properties)
	
	
	
	//
	// Protocols
	//
//	log('protocols=' + JSCocoa.protocols)
//	log('NSObject.protocols=' + NSObject.__protocols);
//	log('NSView.protocols=' + NSView.__protocols);
	
	
	
	//
	// Image names (loaded frameworks)
	//	returns { name : imageName, classNames : [className, className, ...] }
	//
//	log('image names=' + JSCocoa.imageNames)
		
	
			
	//
	// Runtime description
	//
	log('runtime description=' + JSCocoa.runtimeReport)
	
	
	