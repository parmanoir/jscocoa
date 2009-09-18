

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
//	log('NSButton derivation path=' + NSButton.derivationPath)
	// Returns the size of derivation path -1 (Root classes have level 0)
//	log('NSButton derivation level=' + NSButton.derivationLevel)


	//
	// Which frameworks defines the class ?
	//

	// Path to framework defining the class
//	log('framework defining NSView=' + NSView.classImage)

	
	//
	// Method list
	//

	// Own methods : returns an array containing the methods defined by this class level
	//	name
	//	encoding
	//	type (instance|class)
	//	class
	//	framework (path to lib defining the method implementation)
//	log('NSView.ownMethods=' + NSView.ownMethods)

	// Methods : returns an array containing all methods defined in this class
//	log('NSView.methods=' + NSView.methods)


	//
	// Subclasses
	//
//	log('NSView.subclasses=' + NSView.subclasses)

	// Display subclasses as a tree
//	log('NSView.subclassTree=\n' + NSView.subclassTree)
	log('NSObject.subclassTree=\n' + NSObject.subclassTree)
	
	
	log(NSView.ivars)
	log(NSView.properties)