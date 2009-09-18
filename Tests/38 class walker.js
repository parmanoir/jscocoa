

	//
	// Exploring the runtime !
	//



	// All classes defined in the runtime. Right now this returns class names, not classes themselves
//	log('rootClasses=' + JSCocoa.rootclasses)
	// All root classes (NSObject, NSProxy)
//	log('classes=' + JSCocoa.classes)
	
	// Returns an array containing all superclasses and this class : NSObject, NSResponder, NSView, NSControl, NSButton
//	log('NSButton derivation path=' + NSButton.derivationPath)
	// Returns the size of derivation path -1 (Root classes have level 0)
//	log('NSButton derivation level=' + NSButton.derivationLevel)

	// Path to framework defining the class
//	log('framework defining NSView=' + NSView.classImage)

	// Own methods : returns an array containing the methods defined by this class level
	//	name
	//	encoding
	//	type (instance|class)
	//	class
	//	framework (path to lib defining the method implementation)
//	log('NSView.ownMethods=' + NSView.ownMethods)

	// Methods : returns an array containing all methods defined in this class
//	log('NSView.methods=' + NSView.methods)


	log(NSView._subclasses)