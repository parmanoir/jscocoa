//
//  BridgeSupportController.m
//  JSCocoa
//
//  Created by Patrick Geiller on 08/07/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BridgeSupportController.h"


@implementation BridgeSupportController


+ (id)sharedController
{
	static id singleton;
	@synchronized(self)
	{
		if (!singleton)
			singleton = [[BridgeSupportController alloc] init];
		return singleton;
	}
	return singleton;
}

- (id)init
{
	id r = [super init];
	
	paths			= [[NSMutableArray alloc] init];
	xmlDocuments	= [[NSMutableArray alloc] init];
	hash			= [[NSMutableDictionary alloc] init];
	
	return	r;
}

- (void)dealloc
{
	[hash release];
	[paths release];
	[xmlDocuments release];

	[super dealloc];
}

- (BOOL)loadBridgeSupport:(NSString*)path
{
	NSError*	error = nil;

	/*
		Adhoc parser
			NSXMLDocument is too slow
			loading xml document as string then querying on-demand is too slow
			can't get CFXMLParserRef to work
			don't wan't to delve into expat
			-> ad hoc : load file, build a hash of { name : xmlTagString }
	*/
	NSString* xmlDocument = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
	if (error)	return	NSLog(@"loadBridgeSupport : %@", error), NO;

	char* c = (char*)[xmlDocument UTF8String];
#ifdef __OBJC_GC__
	char* originalC = c;
	[[NSGarbageCollector defaultCollector] disableCollectorForPointer:originalC];
#endif
	// Start parsing
	for (; *c; c++)
	{
		if (*c == '<')
		{
			char startTagChar = c[1];
			if (startTagChar == 0)	return	NO;

			// 'co'	constant
			// 'cl'	class
			// 'e'	enum
			// 'fu'	function
			// 'st'	struct
			if ((c[1] == 'c' && (c[2] == 'o' || c[2] == 'l')) || c[1] == 'e' || (c[1] == 'f' && c[2] == 'u') || (c[1] == 's' && c[2] == 't'))
			{
				// Extract name
				char* tagStart = c;
				for (; *c && *c != '\''; c++);
				c++;
				char* c0 = c;
				for (; *c && *c != '\''; c++);
				
				id name = [[NSString alloc] initWithBytes:c0 length:c-c0 encoding:NSUTF8StringEncoding];
				
				// Move to tag end
				BOOL foundEndTag = NO;
				BOOL foundOpenTag = NO;
				c++;
				for (; *c && !foundEndTag; c++)
				{
					if (*c == '<')					foundOpenTag = YES;
					else	
					if (*c == '/')
					{
						if (!foundOpenTag)
						{
							if(c[1] == '>')	foundEndTag = YES, c++;
						}
						else
						{
							if (startTagChar == c[1])	
							{
								foundEndTag = YES;
								// Skip to end of tag
								for (; *c && *c != '>'; c++);
							}
						}
					}
				}
				
				c0 = tagStart;
				id value = [[NSString alloc] initWithBytes:c0 length:c-c0 encoding:NSUTF8StringEncoding];
				
				[hash setValue:value forKey:name];
				[value release];
				[name release];
			}
		}
	}
#ifdef __OBJC_GC__
	[[NSGarbageCollector defaultCollector] enableCollectorForPointer:originalC];
#endif
	[paths addObject:path];
	[xmlDocuments addObject:xmlDocument];

	return	YES;
}


- (BOOL)isBridgeSupportLoaded:(NSString*)path
{
	NSUInteger idx = [self bridgeSupportIndexForString:path];
	return	idx == NSNotFound ? NO : YES;
}

//
// bridgeSupportIndexForString
//	given 'AppKit', return index of '/System/Library/Frameworks/AppKit.framework/Versions/C/Resources/BridgeSupport/AppKitFull.bridgesupport'
//
- (NSUInteger)bridgeSupportIndexForString:(NSString*)string
{
	int i, l = [paths count];
	for (i=0; i<l; i++)
	{
		NSString* path = [paths objectAtIndex:i];
		NSRange range = [path rangeOfString:string];

		if (range.location != NSNotFound)	return	range.location;		
	}
	return	NSNotFound;
}

- (NSString*)queryName:(NSString*)name
{
	return [hash valueForKey:name];
}
- (NSString*)queryName:(NSString*)name type:(NSString*)type
{
	id v = [self queryName:name];
	if (!v)	return	nil;
	
	char* c = (char*)[v UTF8String];
	// Skip tag start
	c++;
	char* c0 = c;
	for (; *c && *c != ' '; c++);
	id extractedType = [[NSString alloc] initWithBytes:c0 length:c-c0 encoding:NSUTF8StringEncoding];
	[extractedType autorelease];
//	NSLog(@"extractedType=%@", extractedType);
	
	if (![extractedType isEqualToString:type])	return	nil;
	return	v;
}

@end







