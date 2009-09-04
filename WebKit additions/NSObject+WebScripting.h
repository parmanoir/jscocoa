//
//  NSObject+WebScripting.h
//  Chocolate
//
//  Created by Fabien Franzen on 02-09-09.
//  Copyright 2009 Atelier Fabien. All rights reserved.
//
//  Getter shortcut on () javascript method calls:
//
//  window.bridgedObject('deep.reaching.keyPath');
//
//  Alternatively:
//
//  window.bridgedObject.deep().reaching().keyPath();
//
//  Setter shortcut on () javascript method calls:
//
//  window.bridgedObject('deep.reaching.keyPath', value);
//

#import <Cocoa/Cocoa.h>

@class WebScriptObject;

@interface NSObject (WebScripting)

+ (id)JSProxyFrom:(id)object; // looks for @selector(JSProxy)

- (id)defaultWebScriptProxy;
- (void)setWebScriptValue:(id)value forKeyPath:(NSString *)keyPath;
- (id)webScriptValueForKeyPath:(NSString *)keyPath;

+ (NSArray *)arrayFromJavaScriptArray:(WebScriptObject *)javaScriptArray;

@end
