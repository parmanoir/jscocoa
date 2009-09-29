//
// Sample code to use JSCocoa in a WebView instead of the existing WebKit bridge.
// by Fabien Franzen on 20090906
//
// Init JSCocoa with initWithGlobalContext:[[webView mainFrame] globalContext]
//
// Use JSCocoa via the global 'OSX' property :
//	var objCDate = OSX.NSDate.alloc.init
//	var point = new OSX.NSPoint(123, 456)
//	var delegate = OSX.NSApplication.sharedApplication.delegate
//	var array = delegate.testArray( ['hello', 'world', [4, 5, 6], 'end' ] )
//
// The Javascript context (JSGlobalContextRef) is only valid for the current webpage : it will be released when navigating to a new URL.
// Destroy and recreate JSCocoa upon WebFrameLoadDelegate.didClearWindowObject:forFrame:
//

@interface Report : NSObject {
    WebView *webView;
    JSCocoaController *JSController;
}

@property (nonatomic, assign) IBOutlet WebView *webView; // weak ref
@property (nonatomic, retain) JSCocoaController *JSController;

- (id)initWithWebView:(WebView *)wView;

- (void)initJSController;

@end

@implementation Report

- (id)initWithWebView:(WebView *)wView {
    if (self = [super init]) {
        [self setWebView:wView];
        [self initJSController];
        [[self webView] setFrameLoadDelegate:self]       
    }
    return self;
}

- (void)initJSController {
    JSGlobalContextRef ctx = [[[self webView] mainFrame] globalContext];
    if ([self JSController] == nil || ([self JSController] && ctx != [[self JSController] ctx])) {
        [self setJSController:[[JSCocoa alloc] initWithGlobalContext:ctx]];
    }
}

#pragma mark WebFrameLoadDelegate Methods

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame {
    [self initJSController];    
    [[self JSController] setObject:self withName:@"report"];
}

#pragma mark -

- (void)dealloc {
    webView = nil;
    [JSController release], JSController = nil;
    [super dealloc];
}

@end

// used with jquery.js and chain.js

jQuery(function($) {
  $('#overview').items([]).chain();
});

function update() {
  var objects = window.report.representedObjects;
  var items = $.map(objects, function(item, idx) {
    return { name: item.name.valueOf(), country: item.country.name.valueOf() };
  });
  $('#overview').items('replace', items);
}