
	// blank : used by TestsRunner to test the evalJSFile delegate method

var f = function(err) {
   log("Hello from a jsfunction " + err);
};

var objcBlock = JSTestBlocks.newErrorBlockForJSFunction_(f);

JSTestBlocks.testFunction_(objcBlock);
