
	// blank : used by TestsRunner to test the evalJSFile delegate method

var f = function(err) {
   log("Hello from a jsfunction");
};

var objcBlock = JSTestBlocks.newErrorBlockForJSFunction_(f);

log('block=' + objcBlock);

JSTestBlocks.testFunction_(objcBlock);
