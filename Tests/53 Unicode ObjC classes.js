

	@implementation Élève : NSObject
	
	- (NSString*)sayHello:(NSString*)str
	{
		return ('Hello ' + str)
	}
	
	@end

	
	var o = [Élève instance]
	var message = o.sayHello('world')
//	log('message=' + message)
	if (message != 'Hello world')			throw 'Unicode ObjC classes failed (1)'

	
	@implementation ファイナンス : NSObject
	
	- (int)スチール追加:(int)一 熱:(int)二
	{
		return 一 + 二
	}
	
	- (id)だけを追加する:(id)一
	{
		return [NSNumber numberWithInt:[一 intValue] + 1]
	}
	
	
	
	@end
	
	
	var o = [ファイナンス instance]
	var r = [o スチール追加:3 熱:7]

//	log('res=' + r)	

	if (r != 10)							throw 'Unicode ObjC classes failed (2)'
	
	
	o = null