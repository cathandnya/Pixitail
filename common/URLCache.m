//
//  URLCache.m
//  EchoPro
//
//  Created by nya on 09/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "URLCache.h"
#import <pthread.h>
#import "NSDataReferer.h"


#ifdef MACOS
	#define UIImage	NSImage
#endif


@implementation URLCache

- (id) init {
	self = [super init];
	if (self) {
		cache = [[NSMutableDictionary alloc] init];
		
		queue_ = [[NSMutableArray alloc] init];
		pthread_mutex_init(&queueMutex_, NULL);
		pthread_cond_init(&queueCond_, NULL);
		
		[NSThread detachNewThreadSelector:@selector(downloadThread) toTarget:self withObject:nil];
		[NSThread detachNewThreadSelector:@selector(downloadThread) toTarget:self withObject:nil];
		[NSThread detachNewThreadSelector:@selector(downloadThread) toTarget:self withObject:nil];
		[NSThread detachNewThreadSelector:@selector(downloadThread) toTarget:self withObject:nil];
		[NSThread detachNewThreadSelector:@selector(downloadThread) toTarget:self withObject:nil];
		[NSThread detachNewThreadSelector:@selector(downloadThread) toTarget:self withObject:nil];
		[NSThread detachNewThreadSelector:@selector(downloadThread) toTarget:self withObject:nil];
		[NSThread detachNewThreadSelector:@selector(downloadThread) toTarget:self withObject:nil];
	}
	return self;
}

- (void) dealloc {
	[cache release];
	[queue_ release];
	pthread_mutex_destroy(&queueMutex_);
	pthread_cond_destroy(&queueCond_);
	
	[super dealloc];
}

+ (URLCache *) sharedInstance {
	static URLCache *obj = nil;
	if (obj == nil) {
		obj = [[URLCache alloc] init];
	} 
	return obj;
}

- (void) pause {
	pthread_mutex_lock(&queueMutex_);
	pause_ = YES;
	pthread_mutex_unlock(&queueMutex_);
}

- (void) resume {
	pthread_mutex_lock(&queueMutex_);
	pause_ = NO;
	pthread_cond_broadcast(&queueCond_);
	pthread_mutex_unlock(&queueMutex_);
}

- (void) downloadThread {
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	while (1) {
		NSAutoreleasePool	*pool2 = [[NSAutoreleasePool alloc] init];
		NSString			*url = nil;
		id					ret = nil;
		
		// 待つ
		pthread_mutex_lock(&queueMutex_);
		while ([queue_ count] == 0 || pause_) {
			pthread_cond_wait(&queueCond_, &queueMutex_);
		}
		pthread_mutex_unlock(&queueMutex_);
		
		//@synchronized(self) {	
		{
			pthread_mutex_lock(&queueMutex_);
			if ([queue_ count] > 0) {
				url = [[[queue_ objectAtIndex:0] retain] autorelease];
				[queue_ removeObjectAtIndex:0];
			}
			pthread_mutex_unlock(&queueMutex_);
			
			if (url) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];
				ret = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url] fromReferer:@"http://www.pixiv.net/"]];
				//ret = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url] fromReferer:@"http://www.pixa.cc/"]];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
				if (ret) {
					@synchronized(self) {	
						[cache setObject:ret forKey:url];
					}
					[ret release];
				} else {
					//pthread_mutex_lock(&queueMutex_);
					//[queue_ addObject:url];
					//pthread_mutex_unlock(&queueMutex_);
				}
			}

		}

		if (ret) {
			[[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"URLCacheCompletedNotification_%@", url] object:self userInfo:[NSDictionary dictionaryWithObject:url forKey:@"URLString"]];
			//[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.8]];
		} else {
			[[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"URLCacheCompletedNotification_%@", url] object:self userInfo:[NSDictionary dictionaryWithObject:[NSNull null] forKey:@"URLString"]];
			//[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
		}
		
		[pool2 release];
	}
	
	[pool release];
}

- (id) objectForURL:(NSString *)url priority:(BOOL)b {
	id ret = nil;
	@synchronized(self) {
		ret = [cache objectForKey:url];
		if (ret == nil) {
			pthread_mutex_lock(&queueMutex_);
			if (![queue_ containsObject:url]) {
				if (b) {
					[queue_ insertObject:url atIndex:0];
				} else {
					[queue_ addObject:url];
				}
				pthread_cond_signal(&queueCond_);
			}
			pthread_mutex_unlock(&queueMutex_);
		}
	}
	return ret;
}

- (id) objectForURL:(NSString *)url {
	return [self objectForURL:url priority:NO];
}

- (id) objectForURLPriory:(NSString *)url {
	return [self objectForURL:url priority:YES];
}

- (void) clearQueue {
	@synchronized(self) {
		[cache removeAllObjects];
	}
}

- (void) setObject:(id)img forURL:(NSString *)url {
	@synchronized(self) {
		[cache setObject:img forKey:url];
	}
}

- (void) removeObjectForURL:(NSString *)url {
	@synchronized(self) {
		if ([cache objectForKey:url]) {
			[cache removeObjectForKey:url];
		}
	}
}

@end
