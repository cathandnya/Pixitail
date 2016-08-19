//
//  CHURLImageLoader.m
//  pixiViewer
//
//  Created by nya on 09/12/21.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CHURLImageLoader.h"


@implementation CHURLImageLoader

@synthesize retryCount, url, referer, object, delegate, percent;

- (CHURLImageLoader *) copy {
	CHURLImageLoader *obj = [[CHURLImageLoader alloc] init];
	obj.retryCount = self.retryCount;
	obj.url = self.url;
	obj.referer = self.referer;
	obj.object = self.object;
	obj.delegate = self.delegate;
	return obj;
}

- (void) dealloc {
	[self cancel];

	[url release];
	[referer release];
	[object release];
	
	[super dealloc];
}

- (void) cancel {
	if (imageConnection_) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];	
	}
	[imageConnection_ cancel];
	[imageConnection_ release];
	imageConnection_ = nil;
	[imageData_ release];
	imageData_ = nil;
	
	self.delegate = nil;
}

- (void) load {
	if (imageConnection_) {
		assert(0);
	}
	
	NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:self.url];
	if (self.referer) {
		[req setValue:self.referer forHTTPHeaderField:@"Referer"];
	}
	imageConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	imageData_ = [[NSMutableData alloc] init];
	[req release];
	
	percent = 0;
	imageDataLength_ = 0;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	[imageConnection_ start];
}

#pragma mark-

- (void) connection:(NSURLConnection *)con didReceiveResponse:(NSURLResponse *)response {
	imageDataLength_ = [response expectedContentLength];
	percent = 0;
}

- (void) connection:(NSURLConnection *)con didReceiveData:(NSData *)data {
	[imageData_ appendData:data];
	
	percent = 100 * [imageData_ length] / imageDataLength_;
	if ([(id)self.delegate respondsToSelector:@selector(loader:progress:)]) {
		[self.delegate loader:self progress:percent];
	}	
}

- (void) connection:(NSURLConnection *)con didFailWithError:(NSError *)error {
	DLog(@"didFailWithError: %@", [error description]);
	DLog(@" %@", [self.url description]);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];

	[imageData_ release];
	imageData_ = nil;
	[imageConnection_ release];
	imageConnection_ = nil;
	
	if ([(id)self.delegate respondsToSelector:@selector(loader:finished:)]) {
		[self.delegate loader:self finished:nil];
	}
}

- (void) connectionDidFinishLoading:(NSURLConnection *)con {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];

	percent = 100;
	if ([(id)self.delegate respondsToSelector:@selector(loader:finished:)]) {
		[self.delegate loader:self finished:imageData_];
	}
	
	[imageData_ release];
	imageData_ = nil;
	[imageConnection_ release];
	imageConnection_ = nil;	
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)con willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

@end
