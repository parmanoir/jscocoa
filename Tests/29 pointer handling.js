

	/*
		

	*/



/*

http://www.cocoabuilder.com/archive/message/cocoa/2006/11/12/174339


static CGColorRef CGColorCreateFromNSColor (CGColorSpaceRef  
colorSpace, NSColor *color)


   NSColor *deviceColor = [color colorUsingColorSpaceName:  
NSDeviceRGBColorSpace];


   float components[4];
   [deviceColor getRed: &components[0] green: &components[1] blue:  
&components[2] alpha: &components[3]];

   return CGColorCreate (colorSpace, components);
*/

//	CGColorGetComponents
/*
	var buffer = new memoryBuffer
	buffer.fill(['f', 1.0, 'f', 0.8, 'f', 0.6, 'f', 0.2])

	throw '29 pointer'


*/