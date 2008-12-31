
//
// Put your Javascript code here. It will be called on application delegate's awakeFromNib.
//


	log('Hello from JSCocoa !')

	var apps = NSWorkspace.sharedWorkspace.launchedApplications
	log(apps.length + ' applications are running')
	for (var i=0; i<apps.length; i++)
		log(i + '=' + apps[i].NSApplicationName)

//	log(apps)
