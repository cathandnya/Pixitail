//
//  NetworkActivityIndicator.m
//  EchoPro
//
//  Created by nya on 09/08/13.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NetworkActivityIndicator.h"


@implementation NetworkActivityIndicator

+ (NetworkActivityIndicator *) sharedInstance {
	static NetworkActivityIndicator *obj = nil;
	if (obj == nil) {
		obj = [[NetworkActivityIndicator alloc] init];
	}
	return obj;
}

- (id) init {
	self = [super init];
	if (self) {
		count_ = 0;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(start) name:@"NetworkActivityIndicatorStartNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(end) name:@"NetworkActivityIndicatorEndNotification" object:nil];
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (void) setIndicator:(NSNumber *)b {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = [b boolValue];
}

- (void) start {
	@synchronized(self) {
		count_++;
		if (count_ == 1) {
			[self performSelectorOnMainThread:@selector(setIndicator:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:YES];
		}
		DLog(@"NetworkActivityIndicator start: %d", count_);
	}
}

- (void) end {
	@synchronized(self) {
		count_--;
		if (count_ == 0) {
			[self performSelectorOnMainThread:@selector(setIndicator:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:YES];
		}
		//assert(count_ >= 0);
		DLog(@"NetworkActivityIndicator end: %d", count_);
	}
}

@end
