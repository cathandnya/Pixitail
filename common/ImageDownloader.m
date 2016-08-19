//
//  ImageDownloader.m
//  pixiViewer
//
//  Created by nya on 11/01/19.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ImageDownloader.h"


@implementation ImageDownloader

@synthesize url, savePath, referer, object, delegate;

- (void) dealloc {
	[self cancel];
	
	self.url = nil;
	self.savePath = nil;
	self.referer = nil;
	self.object = nil;
	
	[super dealloc];
}

#pragma mark-

- (NSString *) tmpPath {
	return [self.savePath stringByAppendingPathExtension:@"temp"];
}

- (void) clean {
	[self cancel];
}

- (void) failed:(NSError *)err {
	[self clean];
	
	[delegate performSelector:@selector(imageDownloader:finished:) withObject:self withObject:err];
}

- (void) completed {
	[fileHandle closeFile];
	[fileHandle release];
	fileHandle = nil;

	[[NSFileManager defaultManager] moveItemAtPath:[self tmpPath] toPath:self.savePath error:nil];

	[self clean];

	[delegate performSelector:@selector(imageDownloader:finished:) withObject:self withObject:nil];
}

#pragma mark-

- (void) download {
	[[NSData data] writeToFile:[self tmpPath] atomically:YES];
	fileHandle = [[NSFileHandle fileHandleForWritingAtPath:[self tmpPath]] retain];
		
	NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	if (self.referer) {
		[req setValue:self.referer forHTTPHeaderField:@"Referer"];
	}
	
	imageConnection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[req release];
				
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	[imageConnection start];
}

- (void) cancel {
	if (imageConnection) {
		[imageConnection cancel];
		[imageConnection release];
		imageConnection = nil;

		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	}

	[fileHandle release];
	fileHandle = nil;
}

#pragma mark-

- (void) connection:(NSURLConnection *)con didReceiveData:(NSData *)data {
	[fileHandle writeData:data];
}

- (void) connection:(NSURLConnection *)con didFailWithError:(NSError *)error {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	[imageConnection release];
	imageConnection = nil;
	
	[self failed:error];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)con {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	[imageConnection release];
	imageConnection = nil;

	[self completed];
}

@end
