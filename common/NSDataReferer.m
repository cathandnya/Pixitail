//
//  NSDataReferer.m
//  pixiViewer
//
//  Created by nya on 09/09/22.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSDataReferer.h"
#import "CHHttpTimeoutableConnection.h"


@implementation NSData(Referer)
+ (id) dataWithContentsOfURL:(NSURL *)url fromReferer:(NSString *)ref {
	NSData						*data = nil;
	NSMutableURLRequest			*req = [[NSMutableURLRequest alloc] initWithURL:url];
	
	[req setValue:ref forHTTPHeaderField:@"Referer"];
	
	NSURLResponse			*res;
	NSError					*err = nil;
	NSData					*postRet;
	
	postRet = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	[req release];
	if (err == nil) {
		data = postRet;
	}
	return data;
	
}
+ (id) dataWithContentsOfURL:(NSURL *)url fromReferer:(NSString *)ref timeout:(NSTimeInterval)ti {
	NSData						*data = nil;
	NSMutableURLRequest			*req = [[NSMutableURLRequest alloc] initWithURL:url];
	
	[req setValue:ref forHTTPHeaderField:@"Referer"];
	
	CHHttpTimeoutableConnection	*con = [[CHHttpTimeoutableConnection alloc] initWithRequest:req];
	data = [con startWithTimeout:ti];
	[con release];
	return data;
}
@end

