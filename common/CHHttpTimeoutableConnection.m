//
//  CHHttpTimeoutableConnection.m
//  pixiViewer
//
//  Created by nya on 09/09/06.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CHHttpTimeoutableConnection.h"
//#import <Foundation/NSConnection.h>
#import <pthread.h>
#include <sys/time.h>


@implementation CHHttpTimeoutableConnection

- (void) createConnectionMain:(NSURLRequest *)req {
	connection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
}

- (id) initWithRequest:(NSURLRequest *)req {
	self = [super init];
	if (self) {
		[self performSelectorOnMainThread:@selector(createConnectionMain:) withObject:req waitUntilDone:YES];
		//connection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
		pthread_cond_init(&cond_, NULL);
		pthread_mutex_init(&mutex_, NULL);
	}
	return self;
}

- (void) dealloc {
	[connection_ release];
	pthread_mutex_destroy(&mutex_);
	pthread_cond_destroy(&cond_);
	
	[super dealloc];
}


- (NSData *) startWithTimeout:(NSTimeInterval)ti {
	int		ret = 0;

	data_ = [[NSMutableData alloc] init];

	//[connection_ scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
	//[connection_ scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSConnectionReplyMode];

	pthread_mutex_lock(&mutex_);
	finished_ = NO;
	completed_ = NO;
	//[connection_ performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
	[connection_ start];
	while (!finished_ && ret == 0) {
		struct timespec timeout;
		struct timeval	tv;
		gettimeofday(&tv, NULL);
		timeout.tv_sec = tv.tv_sec + ceil(ti);
		timeout.tv_nsec = 0;

		ret = pthread_cond_timedwait(&cond_, &mutex_, &timeout);
	}
	if (ret == ETIMEDOUT) {
		// タイムアウト
		[connection_ cancel];
		completed_ = NO;
	}
	if (!completed_) {
		[data_ release];
		data_ = nil;
	}
	pthread_mutex_unlock(&mutex_);
	
	return [data_ autorelease];
}


- (void) connection:(NSURLConnection *)con didReceiveResponse:(NSURLResponse *)response {
}

- (void) connection:(NSURLConnection *)con didReceiveData:(NSData *)data {
	pthread_mutex_lock(&mutex_);
	[data_ appendData:data];
	pthread_cond_signal(&cond_);		// データ来たら起こす
	pthread_mutex_unlock(&mutex_);
}


- (void) connection:(NSURLConnection *)con didFailWithError:(NSError *)error {
	pthread_mutex_lock(&mutex_);
	finished_ = YES;
	completed_ = NO;
	pthread_cond_signal(&cond_);
	pthread_mutex_unlock(&mutex_);
}

- (void) connectionDidFinishLoading:(NSURLConnection *)con {
	pthread_mutex_lock(&mutex_);
	finished_ = YES;
	completed_ = YES;
	pthread_cond_signal(&cond_);
	pthread_mutex_unlock(&mutex_);
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)con willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

@end
